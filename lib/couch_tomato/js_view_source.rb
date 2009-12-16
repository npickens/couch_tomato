require 'digest/sha1'

module CouchTomato
  class JsViewSource
    # todo: provide a 'dirty?' method that can be called in an initializer and warn the developer that view are out of sync
    # todo: provide more granular information about which views are being modified
    # todo: limitation (bug?) where if you remove a database's views entirely from the file system, view's will not be removed from the database as may be expected
    def self.push(silent=false)
      fs_database_names.each do |database_name|
        db = database!(database_name)

        fs_docs = fs_design_docs(database_name)
        db_docs = db_design_docs(db)

        fs_docs.each do |design_name, fs_doc|
          db_doc = db_docs[design_name]

          if db_doc
            fs_doc['_id'] = db_doc['_id']
            fs_doc['_rev'] = db_doc['_rev']
          end

          if fs_doc['views'].empty?
            next unless fs_doc['_rev']
            puts "DELETE #{fs_doc['_id']}" unless silent
            db.delete_doc(fs_doc)
          else
            if changed_views?(fs_doc, db_doc)
              puts "UPDATE #{fs_doc['_id']}" unless silent
              db.save_doc(fs_doc)
            end
          end
        end
      end
    end

    def self.changed_views?(fs_doc, db_doc)
      return true if db_doc.nil?

      fs_doc['views'].each do |name, fs_view|
        db_view = db_doc['views'][name]
        %w(map reduce).each do |method|
          return true if db_view.nil? || db_view["sha1-#{method}"] != fs_view["sha1-#{method}"]
        end
      end

      return fs_doc['views'].length != db_doc['views'].length
    end

    def self.diff
      status_dict = {
        :NEW_DOC  => "new design:", :NEW_VIEW => "new view:", 
        :MOD_VIEW => "modified:",   :DEL_DOC  => "deleted:", 
        :DEL_VIEW => "deleted:",    :NEW_DB => "new db:"
      }
      types = ["map", "reduce"]
      puts "# Changes with respect to the filesystem:"
      
      fs_database_names.each do |database_name|
        db = database(database_name)
        puts "#\t#{setw(status_dict[:NEW_DB], 14)}#{database_name}" unless is_db?(db)
        
        fs_docs = fs_design_docs(database_name)
        db_docs = is_db?(db) ? db_design_docs(db) : {}

        diff = []
        # design docs on fs but not in db
        (fs_docs.keys - db_docs.keys).each do |design_name|
          unless fs_docs[design_name]['views'].empty?
            diff.push [:NEW_DOC, "#{database_name}/_#{design_name}"]
            fs_docs[design_name]['views'].keys.each do |view| 
              (fs_docs[design_name]['views'][view].keys & types).each {|type|
                diff.push [:NEW_VIEW, "#{database_name}/_#{design_name}/#{view}-#{type}"]}
            end
          end
        end

        # design docs in db but not on fs
        (db_docs.keys - fs_docs.keys).each do |design_name|
          diff.push [:DEL_DOC, "#{database_name}/_#{design_name}"] unless (design_name.to_s.include? "migrations")
        end

        # design docs in both db and fs
        (fs_docs.keys & db_docs.keys).each do |design_name|
          common_view_keys = (fs_docs[design_name]['views'].keys & db_docs[design_name]['views'].keys)
          fs_only_view_keys = fs_docs[design_name]['views'].keys - common_view_keys
          db_only_view_keys = db_docs[design_name]['views'].keys - common_view_keys

          unless fs_only_view_keys.empty?
            methods = fs_only_view_keys.map do |key|
              %w(map reduce).map {|method| fs_docs[design_name]['views'][key][method].nil? ? nil : "#{key}-#{method}"}.compact
            end.flatten
            methods.each {|method| diff.push [:NEW_VIEW, "#{database_name}/_#{design_name}/#{method}"] }
          end

          unless db_only_view_keys.empty?
            methods = db_only_view_keys.map do |key|
              %w(map reduce).map {|method| db_docs[design_name]['views'][key][method] ? "#{key}-#{method}" : nil}.compact
            end
            methods.each {|method| diff.push [:DEL_VIEW, "#{database_name}/_#{design_name}/#{method}"] }
          end

          common_view_keys.each do |common_key|
            # are the sha's the same?
            # map reduce sha1
            fs_view = fs_docs[design_name]['views'][common_key]
            db_view = db_docs[design_name]['views'][common_key]

            # has either the map or reduce been added or removed
            %w(map reduce).each do |method|
              if db_view[method] && !fs_view[method]
                diff.push [:DEL_VIEW, "#{database_name}/_#{design_name}/#{common_key}-#{method}"]  and next
              end

              if fs_view[method] && !db_view[method]
                diff.push [:NEW_VIEW, "#{database_name}/_#{design_name}/#{common_key}-#{method}"]  and next
              end

              if fs_view["sha1-#{method}"] != db_view["sha1-#{method}"]
                diff.push [:MOD_VIEW, "#{database_name}/_#{design_name}/#{common_key}-#{method}"]  and next
              end
            end
          end
        end
        
        diff.uniq!
        diff.each do |status|
          puts "#\t#{setw(status_dict[status.first], 14)}#{status.last}"
        end
      end
    end

    private
    
    def self.setw(str, w)
      spaces = w - str.length
      (spaces > 0) ? str + (" " * spaces) : str
    end

    def self.path(db_name="")
      "#{Rails.root}/couchdb/views/#{db_name}" if Rails
    end

    def self.fs_database_names
      Dir[path + "/**"].map {|path| path.split('/').last}
    end

    def self.db_design_docs(db)
      design_docs = db.get("_all_docs", {:startkey => "_design/", :endkey => "_design0", :include_docs => true})['rows']
      design_docs.inject({}) do |res, row|
        doc = row['doc']
        design_name = doc['_id'].split('/').last
        res[design_name.to_sym] = doc#['views']
        res
      end
    end

    # :clicks => {'by_date' => {'map' => ..., 'reduce' => ..., sha1-map => ..., sha1-reduce => ...} }
    def self.fs_design_docs(db_name)
      design_docs = {}

      path = "#{RAILS_ROOT}/couchdb/views/#{db_name}"
      Dir[path + "/**"].each do |file|
        throw "Invalid filename '#{File.basename(file)}': expecting '-map.js' or '-reduce.js' suffix" unless file.match(/-((map)|(reduce))\.js$/)

        design_name = db_name.to_sym
        design_docs[design_name] ||= {'_id' => "_design/#{db_name}", 'views' => {}}
        fs_view(design_docs[design_name], file)
      end

      design_docs.each do |db, design|
        design["views"].each do |view, functions|
          if !functions["reduce"].nil?
            raise "#{view}-reduce was found without a corresponding map function." if functions["map"].nil?
          end
        end
      end

      design_docs
    end

    def self.fs_view(design_doc, view_path)
      filename = view_path.split('/').last.split('.').first
      name, type = filename.split('-')

      file = open(view_path)
      content = file.read
      file.close

      sha1 = Digest::SHA1.hexdigest(content)

      design_doc['views'][name] ||= {}
      design_doc['views'][name][type] = content
      design_doc['views'][name]["sha1-#{type}"] = sha1
      design_doc
    end
    
    def self.touch(dbs, async=false, timeout=nil)
      s = Patron::Session.new
      s.timeout = timeout.nil? ? 86400 : timeout.to_i
      s.timeout = 1 if async
       
      dbs.each do |db_str|
        db = database(db_str)
        design_doc = db_design_docs(db)
        
        doc_id = design_doc[db_str.to_sym]["_id"]
        view = design_doc[db_str.to_sym]["views"].keys.first

        print "Updating #{db_str}... "
        STDOUT.flush
        
        begin
          s.get("#{db_url(db_str)}/#{doc_id}/_view/#{view}?limit=0")
          puts "finished!"
        rescue Patron::TimeoutError
          if async
            puts "task started asynchronously."
          else
            puts "the view could not be built within the specified timeout (#{s.timeout} seconds). The view is still being built in the background."
          end
        end
      end
    end
    
    def self.db_url(database_name)
      "http://" + APP_CONFIG["couchdb_address"] + ":" + APP_CONFIG["couchdb_port"].to_s \
       + "/" + APP_CONFIG["couchdb_basename"] + "_" + database_name + "_" + RAILS_ENV
    end

    # todo: don't depend on "proprietary" APP_CONFIG
    def self.database(database_name, force=false)
      url = db_url(database_name)
      force ? CouchRest.database!(url) : CouchRest.database(url)
    end
    
    def self.database!(database_name)
      database(database_name, true);
    end
    
    def self.is_db?(db) 
      begin
        db.info
      rescue
        return false
      end
      return true
    end
  end
end