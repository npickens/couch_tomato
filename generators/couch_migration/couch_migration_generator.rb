class CouchMigrationGenerator < Rails::Generator::Base
  attr_accessor :migration_class_name

  def manifest
    record do |m|
      db_name = args.shift
      migration_name = args.shift

      dir = "couchdb/migrate/#{db_name}"
      migration_file_name = "#{Time.now.utc.strftime("%Y%m%d%H%M%S")}_#{migration_name}.rb"
      @migration_class_name = migration_name.camelize

      m.directory(dir)
      m.template('migration.rb', File.join(dir, migration_file_name))
    end
  end
end
