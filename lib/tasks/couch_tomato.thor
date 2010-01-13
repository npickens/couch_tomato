Ct_Yml_Example = %(defaults: &defaults
  couchdb_address:         127.0.0.1
  couchdb_port:            5984
  couchdb_basename:        your_project_name

development:
  <<: *defaults

test:
  <<: *defaults

production:
  <<: *defaults
)

STDOUT.sync = true
class CouchTomatoApp < Thor
  include Thor::Actions
  namespace :ct
  
  desc 'init', 'Sets up the required structure for Couch Tomato'
  def init
    load_env
    project_root = ::Rails.root rescue nil || "."
    
    ct_yml_path = "#{project_root}/config/couch_tomato.yml.example"
    couch_folder = "#{project_root}/couchdb"
    
    print "Generating a sample couch_tomato yml... " 
    unless File.exist?(ct_yml_path)
      FileUtils.mkdir "#{project_root}/config"
      File.open(ct_yml_path, 'w') {|f| f.write(Ct_Yml_Example) }
      puts "#{ct_yml_path} created"
    else
      puts "#{ct_yml_path} already exists"
    end

    print "Generating the couchdb folder.......... " 
    puts (File.directory? couch_folder) ? "#{couch_folder} already exists" : "#{FileUtils.mkdir "#{couch_folder}"} created"
    print "Generating couchdb/migrate............. " 
    puts (File.directory? "#{couch_folder}/migrate") ? "#{couch_folder}/migrate already exists" : "#{FileUtils.mkdir "#{couch_folder}/migrate"} created"
    print "Generating couchdb/views............... " 
    puts (File.directory? "#{couch_folder}/views") ? "#{couch_folder}/views already exists" : "#{FileUtils.mkdir "#{couch_folder}/views"} created"
  end
  
  desc 'push', 'Inserts the views into CouchDB'
  method_options %w(RAILS_ENV -e) => :string
  def push
    load_env(options)
    CouchTomato::JsViewSource.push
  end
  
  desc 'diff', 'Compares views in DB and the File System'
  method_options %w(RAILS_ENV -e) => :string
  def diff
    load_env(options)
    CouchTomato::JsViewSource.diff
  end
  
  desc 'drop', 'Drops databases for the current RAILS_ENV; ' + 
       'If no databases are specified, user will be prompted if all databases should be removed; ' + 
       'If the -r option is specified, all databases matching the regex will be dropped.'
    method_options %w(RAILS_ENV -e) => :string, %w(DBS -d) => :array, %w(REGEX -r) => :string
  def drop
    load_env(options)
    dbs = options["DBS"]
    rm_all = false
    rm_all = (yes? "Drop all databases?") if (options['REGEX'].nil? && dbs.nil?)
    
    regex = Regexp.new(options['REGEX'].to_s)
    databases(dbs) do |db, dir|
      if (rm_all || db.name == db.name[regex]) && is_db?(db)
        db.delete!
        puts "Dropped #{db.name}"
      end
    end
  end
  
  desc 'migrate', 'Runs migrations'
  method_options %w(RAILS_ENV -e) => :string, %w(VERSION -v) => :string, %w(STEP -s) => :string, 
    :redo => :boolean, :reset => :boolean, :up => :boolean, :down => :boolean
  def migrate
    load_env(options)
    supported_args = %w(redo reset up down)
    action = supported_args & options.keys
    raise "Cannot provide more than one action." if action.length > 1
    
    action = (action.empty?) ? nil : action.first
    case action
      when nil
        migrate_helper
      #Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.
      when "redo"
        if ENV['VERSION']
          down_helper
          up_helper
        else
          rollback_helper
          migrate_helper
        end
      #Resets your database using your migrations for the current environment
      when "reset"
        invoke :drop
        invoke :push
        migrate_helper
      #Runs the "up" for a given migration VERSION.
      when "up"
        up_helper
      #Runs the "down" for a given migration VERSION.
      when "down"
        down_helper
    end        
  end
    
  desc 'rollback', 'Rolls back to the previous version. Specify the number of steps with STEP=n'
  method_options %w(RAILS_ENV -e) => :string, %w(STEP -s) => :string 
  def rollback
    load_env(options)
    rollback_helper
  end
  
  desc 'forward', 'Rolls forward to the next version. Specify the number of steps with STEP=n'
  method_options %w(RAILS_ENV -e) => :string, %w(STEP -s) => :string 
  def forward
    load_env(options)
    databases do |db, dir|
      CouchTomato::Migrator.forward(db, dir, ENV['STEP'] ? ENV['STEP'].to_i : 1)
    end
  end
  
  desc 'replicate', 'Replicate databases between app environments'
  method_options %w(RAILS_ENV -e) => :string, %w(SRC_DB -c) => :string, 
    %w(DST_DB -v) => :string , %w(SRC_SERVER -s) => :string , %w(DST_SERVER -t) => :string 
  def replicate
    load_env(options)
    src_server, dst_server = servers

    src_db = options['SRC_DB']
    dst_db = options['DST_DB'] || (src_server == dst_server ? "#{src_db}_bak" : src_db)

    replicator = CouchTomato::Replicator.new(src_server, dst_server)
    
    if src_db
      puts "== Replicating '#{src_server}/#{src_db}' to '#{dst_server}/#{dst_db}'"
      replicator.replicate(src_db, dst_db)
    elsif src_server == dst_server
      puts "== Replicating all databases at '#{src_server}' using '_bak' suffix for replicated database names"
      replicator.replicate_all('_bak')
    else
      puts "== Replicating all databases from '#{src_server}' to '#{dst_server}'"
      replicator.replicate_all
    end
  end
  
  desc 'touch', 'Initiates the building of a design document'
  method_options %w(RAILS_ENV -e) => :string, %w(DBS -d) => :array, :async => :boolean, %w(TIMEOUT -t) => :numeric
  def touch
    load_env(options)
    view_path = "couchdb/views"
    valid_dbs = options["DBS"] & (Dir["couchdb/views/**"].map {|db| File.basename(db) })
    CouchTomato::JsViewSource.touch(valid_dbs, options.async?, options['TIMEOUT'])
  end
  
  private
  def up_helper
    version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
    raise 'VERSION is required' unless version

    databases do |db, dir|
      CouchTomato::Migrator.run(:up, db, dir, version)
    end
  end
  
  def down_helper
    version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
    raise 'VERSION is required' unless version

    databases do |db, dir|
      CouchTomato::Migrator.run(:down, db, dir, version)
    end
  end
  
  def rollback_helper
    databases do |db, dir|
      CouchTomato::Migrator.rollback(db, dir, ENV['STEP'] ? ENV['STEP'].to_i : 1)
    end
  end
  
  def migrate_helper
    databases do |db, dir|
      CouchTomato::Migrator.migrate(db, dir, ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
    end
  end
  
  def load_env(options=nil)
    unless (Rails rescue nil)
      print "Loading enviornment... "  
      %w(RAILS_ENV VERSION SRC_SERVER DST_SERVER STEP).each {|var| ENV[var] =
        options[var] unless options[var].nil? } unless options.nil?

      begin
        require(File.join(ENV['PWD'], 'config', 'boot'))
        require(File.join(ENV['PWD'], 'config', 'environment'))
        puts "done."
      rescue LoadError
        puts "could not find environment files. Assuming direct use."
      ensure
        CouchTomato::Config.set_config_yml unless CouchTomato::Config.loaded?
      end
    end
  end

  def servers
    local_server = "http://#{CouchTomato::Config.couch_address}:#{CouchTomato::Config.couch_port}"
    src_server = (ENV['SRC_SERVER'] || local_server).gsub(/\s*\/\s*$/, '')
    dst_server = (ENV['DST_SERVER'] || local_server).gsub(/\s*\/\s*$/, '')

    return src_server, dst_server
  end

  def databases(db_names=nil)
    dirs = Dir['couchdb/migrate/*']
    
    db_map = dirs.inject({}) {|map, dir| map[File.basename(dir)] = dir; map }
    db_names ||= db_map.keys
    db_names.each do |db_name|
      db = CouchTomato::JsViewSource.database(db_name)
      yield db, db_map[db_name]
    end
  end

  def is_db?(db) 
    begin
      db.info
    rescue
      return false
    end
    return true
  end

end
