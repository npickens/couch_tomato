namespace :couch_potato do
  desc 'Inserts the views into CouchDB'
  task :push => :environment do
    CouchPotato::JsViewSource.push
  end

  desc 'Compares views in DB and the File System'
  task :diff => :environment do
    CouchPotato::JsViewSource.diff
  end

  desc 'Drops databases for the current RAILS_ENV'
  task :drop => :environment do
    databases do |db, dir|
      db.delete!
    end
  end

  desc 'Runs migrations'
  task :migrate => :environment do
    databases do |db, dir|
      CouchPotato::Migrator.migrate(db, dir, ENV['VERSION'] ? ENV['VERSION'].to_i : nil)
    end
  end

  namespace :migrate do
    desc 'Rollbacks the database one migration and re migrate up. If you want to rollback more than one step, define STEP=x. Target specific version with VERSION=x.'
    task :redo => :environment do
      if ENV['VERSION']
        Rake::Task['couch_potato:migrate:down'].invoke
        Rake::Task['couch_potato:migrate:up'].invoke
      else
        Rake::Task['couch_potato:rollback'].invoke
        Rake::Task['couch_potato:migrate'].invoke
      end
    end

    desc 'Resets your database using your migrations for the current environment'
    task :reset => ['couch_potato:drop', 'couch_potato:push', 'couch_potato:migrate']

    desc 'Runs the "up" for a given migration VERSION.'
    task :up => :environment do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      databases do |db, dir|
        CouchPotato::Migrator.run(:up, db, dir, version)
      end
    end

    desc 'Runs the "down" for a given migration VERSION.'
    task :down => :environment do
      version = ENV['VERSION'] ? ENV['VERSION'].to_i : nil
      raise 'VERSION is required' unless version

      databases do |db, dir|
        CouchPotato::Migrator.run(:down, db, dir, version)
      end
    end
  end

  desc 'Rolls back to the previous version. Specify the number of steps with STEP=n'
  task :rollback => :environment do
    databases do |db, dir|
      CouchPotato::Migrator.rollback(db, dir, ENV['STEP'] ? ENV['STEP'].to_i : 1)
    end
  end

  desc 'Rolls forward to the next version. Specify the number of steps with STEP=n'
  task :forward => :environment do
    databases do |db, dir|
      CouchPotato::Migrator.forward(db, dir, ENV['STEP'] ? ENV['STEP'].to_i : 1)
    end
  end

  desc 'Replicates couch databases'
  task :replicate => :environment do
    local_server = "http://#{APP_CONFIG['couchdb_address']}:#{APP_CONFIG['couchdb_port']}"
    src_server = (ENV['SRC_SERVER'] || local_server).gsub(/\s*\/\s*$/, '')
    dst_server = (ENV['DST_SERVER'] || local_server).gsub(/\s*\/\s*$/, '')

    src_db = ENV['DB']
    dst_db = ENV['DST_DB'] || (src_server == dst_server ? "#{src_db}_bak" : src_db)

    replicator = CouchPotato::Replicator.new(src_server, dst_server)

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

  namespace :replicate do
    desc 'Replicate databases between app environments'
    task :env => :environment do
      local_server = "http://#{APP_CONFIG['couchdb_address']}:#{APP_CONFIG['couchdb_port']}"
      src_server = (ENV['SRC_SERVER'] || local_server).gsub(/\s*\/\s*$/, '')
      dst_server = (ENV['DST_SERVER'] || local_server).gsub(/\s*\/\s*$/, '')

      src_env = ENV['SRC_ENV'] || 'production'
      dst_env = ENV['SRC_ENV'] || 'development'

      replicator = CouchPotato::Replicator.new(src_server, dst_server)
      replicator.replicate_env(src_env, dst_env, ENV['PREFIX'])
    end
  end

  def databases
    dirs = ENV['DB'] ? ["couchdb/migrate/#{ENV['DB']}"] : Dir['couchdb/migrate/*']
    dirs.each do |dir|
      db_name = File.basename(dir)
      db = CouchPotato::JsViewSource.database!(db_name)
      yield db, dir
    end
  end
end
