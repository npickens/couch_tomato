require 'digest/sha1'
# require 'pp'

module CouchPotato
  class JsViewSource
    # todo: provide a 'dirty?' method that can be called in an initializer and warn the developer that view are out of sync
    # todo: provide more granular information about which views are being modified
    # todo: limitation (bug?) where if you remove a database's views entirely from the file system, view's will not be removed from the database as may be expected
    def self.push
      fs_database_names.each do |database_name|
        db = database!(database_name)
        
        fs_docs = fs_design_docs(database_name)
        db_docs = db_design_docs(db)
        
        fs_docs.each do |design_name, doc|
          if db_docs.keys.include?(design_name)
            doc['_id'] = db_docs[design_name]['_id']
            doc['_rev'] = db_docs[design_name]['_rev']
          end
          
          if doc['views'].empty?
            next unless doc['_rev']
            puts "DELETE #{doc['_id']}"
            db.delete_doc(doc)
          else
            puts "UPDATE #{doc['_id']}"
            db.save_doc(doc)
          end
        end
      end
    end
    
    def self.diff
      fs_database_names.each do |database_name|
        db = database!(database_name)
        
        fs_docs = fs_design_docs(database_name)
        db_docs = db_design_docs(db)
        
        # design docs on fs but not in db
        (fs_docs.keys - db_docs.keys).each do |design_name|
          unless fs_docs[design_name]['views'].empty?
            puts "    NEW: #{database_name}/_#{design_name}: #{fs_docs[design_name]['views'].keys.join(', ')}"
          end
        end
        
        # design docs in db but not on fs
        (db_docs.keys - fs_docs.keys).each do |design_name|
          puts "REMOVED: #{database_name}/_#{design_name}"
        end
        
        # design docs in both db and fs
        (fs_docs.keys & db_docs.keys).each do |design_name|
          common_view_keys = (fs_docs[design_name]['views'].keys & db_docs[design_name]['views'].keys)
          fs_only_view_keys = fs_docs[design_name]['views'].keys - common_view_keys
          db_only_view_keys = db_docs[design_name]['views'].keys - common_view_keys
          
          unless fs_only_view_keys.empty?
            methods = fs_only_view_keys.map do |key|
              %w(map reduce).map {|method| fs_docs[design_name]['views'][key][method].nil? ? nil : "#{key}.#{method}()"}.compact
            end.flatten
            puts "  ADDED: #{database_name}/_#{design_name}: #{methods.join(', ')}"
          end
          
          unless db_only_view_keys.empty?
            methods = db_only_view_keys.map do |key|
              %w(map reduce).map {|method| db_docs[design_name]['views'][key][method] ? "#{key}.#{method}()" : nil}.compact
            end
            puts "REMOVED: #{database_name}/_#{design_name}: #{methods.join(', ')}"
          end
          
          common_view_keys.each do |common_key|
            # are the sha's the same?
            # map reduce sha1
            fs_view = fs_docs[design_name]['views'][common_key]
            db_view = db_docs[design_name]['views'][common_key]
            
            # has either the map or reduce been added or removed
            %w(map reduce).each do |method|
              if db_view[method] && !fs_view[method]
                puts "REMOVED: #{database_name}/_#{design_name}:#{method}()" and next
              end
              
              if fs_view[method] && !db_view[method]
                puts "  ADDED: #{database_name}/_#{design_name}:#{method}()" and next
              end
              
              if fs_view["sha1-#{method}"] != db_view["sha1-#{method}"]
                puts "OUTDATED: #{database_name}/_#{design_name}:#{method}()" and next
              end
            end
          end
        end
        
      end
    end
    
    private
    
    def self.fs_database_names
      path = "#{RAILS_ROOT}/db/views"
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
      path = "#{RAILS_ROOT}/db/views/#{db_name}"
      Dir[path + "/**"].each do |dir|
        view_path = dir.match(/\.js$/) ? dir : nil
        design_name = view_path ? db_name : dir.split('/').last
        
        design_doc = design_docs[design_name.to_sym] || {'_id' => "_design/#{design_name}", 'views' => {}}
        
        if view_path
          fs_view(design_doc, view_path)
        else
          Dir[dir + "/*.js"].each do |view_path|
            fs_view(design_doc, view_path)
          end
        end
        
        design_docs[design_name.to_sym] = design_doc
      end
      design_docs
    end
    
    def self.fs_view(design_doc, view_path)
      # pp design_doc
      # pp view_path
      
      filename = view_path.split('/').last.split('.').first
      name, type = filename.split('-')
      
      file = open(view_path)
      content = file.read.gsub(/\t/, "  ") # todo: why is this needed?
      file.close
      
      sha1 = Digest::SHA1.hexdigest(content)
      
      design_doc['views'][name] ||= {}
      design_doc['views'][name][type] = content
      design_doc['views'][name]["sha1-#{type}"] = sha1
      design_doc
    end
    
    # todo: don't depend on "proprietary" APP_CONFIG
    def self.database!(database_name)
      CouchRest.database!("http://" + APP_CONFIG["couchdb_address"] + ":" + APP_CONFIG["couchdb_port"].to_s \
       + "/" + APP_CONFIG["couchdb_basename"] + "_" + database_name + "_" + RAILS_ENV)
    end
    
  end
end