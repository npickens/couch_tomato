require 'pp'

class Couch_Tomato < Thor
    include Thor::Actions
  desc 'push', 'Inserts the views into CouchDB'
  method_options %w(RAILS_ENV -e) => :string
  def push
    load_rails(options)
    CouchTomato::JsViewSource.push
  end
  
  desc 'diff', 'Compares views in DB and the File System'
  method_options %w(RAILS_ENV -e) => :string
  def diff
    load_rails(options)
    CouchTomato::JsViewSource.diff
  end
  
  desc 'drop', 'Drops databases for the current RAILS_ENV; ' + 
       'If no databases are specified, user will be prompted if all databases should be removed'
  method_options %w(RAILS_ENV -e) => :string
  def drop(*dbs)
    load_rails(options)
    dbs = nil if (dbs.empty?) && (yes? "Drop all databases?")

    databases(dbs) do |db, dir|
      if is_db?(db)
        db.delete!
        puts "Dropped #{db.name}"
      end
    end
  end
  
  desc 'migrate', 'Runs migrations'
  method_options %w(RAILS_ENV -e) => :string, %w(VERSION -v) => :string, %w(STEP -s) => :string, 
    :redo => :boolean, :reset => :boolean, :up => :boolean, :down => :boolean
  def migrate
    load_rails(options)
    supported_args = %w(redo reset up down)
    action = supported_args & options.keys
    raise "Cannot provide more than one action." if action.length != 1
    action = (action.empty?) ? nil : action.first

    case action
      when nil
        migrate_helper
      when "redo"
        if ENV['VERSION']
          down_helper
          up_helper
        else
          rollback_helper
          migrate_helper
        end
      when "reset"
        invoke :drop
        invoke :push
        migrate_helper
      when "up"
        up_helper
      when "down"
        down_helper
    end        
  end
    
  desc 'rollback', 'Rolls back to the previous version. Specify the number of steps with STEP=n'
  method_options %w(RAILS_ENV -e) => :string, %w(STEP -s) => :string 
  def rollback
    load_rails(options)
    rollback_helper
  end
  
  desc 'forward', 'Rolls forward to the next version. Specify the number of steps with STEP=n'
  method_options %w(RAILS_ENV -e) => :string, %w(STEP -s) => :string 
  def forward
    load_rails(options)
    databases do |db, dir|
      CouchTomato::Migrator.forward(db, dir, ENV['STEP'] ? ENV['STEP'].to_i : 1)
    end
  end
  
  desc 'replicate', 'Replicate databases between app environments'
  method_options %w(RAILS_ENV -e) => :string, %w(SRC_DB sd) => :string, 
    %w(DST_DB dd) => :string , %w(SRC_SERVER ss) => :string , %w(DST_SERVER ds) => :string 
  def replicate
    load_rails(options)
    src_server, dst_server = servers

    src_db = ENV['DB']
    dst_db = ENV['DST_DB'] || (src_server == dst_server ? "#{src_db}_bak" : src_db)

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
  
  def load_rails(options=nil)
    %w(RAILS_ENV VERSION SRC_SERVER DST_SERVER STEP).each {|var| ENV[var] =
      options[var] unless options[var].nil? } unless options.nil?

    require(File.join(ENV['PWD'], 'config', 'boot'))
    require(File.join(ENV['PWD'], 'config', 'environment'))
  end

  def servers
    local_server = "http://#{APP_CONFIG['couchdb_address']}:#{APP_CONFIG['couchdb_port']}"
    src_server = (ENV['SRC_SERVER'] || local_server).gsub(/\s*\/\s*$/, '')
    dst_server = (ENV['DST_SERVER'] || local_server).gsub(/\s*\/\s*$/, '')

    return src_server, dst_server
  end

  def databases(db_names=nil)
    #-Do we really need this single db case any more? The function can handle a-----#
    # database sent in as a parameter. Please address ASAP.                         #
    dirs = ENV['DB'] ? ["couchdb/migrate/#{ENV['DB']}"] : Dir['couchdb/migrate/*']  #
    #-------------------------------------------------------------------------------#
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