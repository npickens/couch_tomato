module CouchTomato
  class IrreversibleMigration < StandardError#:nodoc:
  end

  class DuplicateMigrationVersionError < StandardError#:nodoc:
    def initialize(version)
      super("Multiple migrations have the version number #{version}")
    end
  end

  class DuplicateMigrationNameError < StandardError#:nodoc:
    def initialize(name)
      super("Multiple migrations have the name #{name}")
    end
  end

  class UnknownMigrationVersionError < StandardError #:nodoc:
    def initialize(version)
      super("No migration with version number #{version}")
    end
  end

  class IllegalMigrationNameError < StandardError#:nodoc:
    def initialize(name)
      super("Illegal name for migration file: #{name}\n\t(only lower case letters, numbers, and '_' allowed)")
    end
  end

  # MigrationProxy is used to defer loading of the actual migration classes
  # until they are needed
  class MigrationProxy
    attr_accessor :name, :version, :filename

    delegate :migrate, :announce, :write, :to=>:migration

    private
      def migration
        @migration ||= load_migration
      end

      def load_migration
        load(filename)
        name.constantize
      end
  end

  class Migrator#:nodoc:
    class << self
      def migrate(db, migrations_path, target_version = nil)
        case
          when target_version.nil?                  then up(db, migrations_path, target_version)
          when current_version(db) > target_version then down(db, migrations_path, target_version)
          else                                           up(db, migrations_path, target_version)
        end
      end

      def rollback(db, migrations_path, steps=1)
        move(:down, db, migrations_path, steps)
      end

      def forward(db, migrations_path, steps=1)
        move(:up, db, migrations_path, steps)
      end

      def up(db, migrations_path, target_version = nil)
        self.new(:up, db, migrations_path, target_version).migrate
      end

      def down(db, migrations_path, target_version = nil)
        self.new(:down, db, migrations_path, target_version).migrate
      end

      def run(direction, db, migrations_path, target_version)
        self.new(direction, db, migrations_path, target_version).run
      end

      def migrations_doc(db)
        begin
          doc = db.get('_design/migrations')
        rescue RestClient::ResourceNotFound
          db.save_doc('_id' => '_design/migrations', 'versions' => nil)
          doc = db.get('_design/migrations')
        end

        return doc
      end

      def get_all_versions(db)
        doc = migrations_doc(db)

        if doc['versions']
          doc['versions'].sort
        else
          []
        end
      end

      def current_version(db)
        get_all_versions(db).max || 0
      end

      private

      def move(direction, db, migrations_path, steps)
        migrator = self.new(direction, db, migrations_path)
        start_index = migrator.migrations.index(migrator.current_migration) || 0

        finish = migrator.migrations[start_index + steps]
        version = finish ? finish.version : 0
        send(direction, db, migrations_path, version)
      end
    end

    def initialize(direction, db, migrations_path, target_version = nil)
      @db = db
      @migrations_doc = self.class.migrations_doc(@db)
      @direction, @migrations_path, @target_version = direction, migrations_path, target_version
    end

    def current_version
      migrated.last || 0
    end

    def current_migration
      migrations.detect { |m| m.version == current_version }
    end

    def run
      target = migrations.detect { |m| m.version == @target_version }
      raise UnknownMigrationVersionError.new(@target_version) if target.nil?
      unless (up? && migrated.include?(target.version.to_i)) || (down? && !migrated.include?(target.version.to_i))
        target.migrate(@direction, @db)
        record_version_state_after_migrating(target.version)
      end
    end

    def migrate
      current = migrations.detect { |m| m.version == current_version }
      target = migrations.detect { |m| m.version == @target_version }

      if target.nil? && !@target_version.nil? && @target_version > 0
        raise UnknownMigrationVersionError.new(@target_version)
      end

      start = up? ? 0 : (migrations.index(current) || 0)
      finish = migrations.index(target) || migrations.size - 1
      runnable = migrations[start..finish]

      # skip the last migration if we're headed down, but not ALL the way down
      runnable.pop if down? && !target.nil?

      runnable.each do |migration|
        RAILS_DEFAULT_LOGGER.info("Migrating to #{migration.name} (#{migration.version})")

        # On our way up, we skip migrating the ones we've already migrated
        next if up? && migrated.include?(migration.version.to_i)

        # On our way down, we skip reverting the ones we've never migrated
        if down? && !migrated.include?(migration.version.to_i)
          migration.announce 'never migrated, skipping'; migration.write
          next
        end

        begin
          migration.migrate(@direction, @db)
          record_version_state_after_migrating(migration.version)
        rescue => e
          raise StandardError, "An error has occurred, all later migrations canceled:\n\n#{e}", e.backtrace
        end
      end
    end

    def migrations
      @migrations ||= begin
        files = Dir["#{@migrations_path}/[0-9]*_*.rb"]

        migrations = files.inject([]) do |klasses, file|
          version, name = file.scan(/([0-9]+)_([_a-z0-9]*).rb/).first

          raise IllegalMigrationNameError.new(file) unless version
          version = version.to_i

          if klasses.detect { |m| m.version == version }
            raise DuplicateMigrationVersionError.new(version)
          end

          if klasses.detect { |m| m.name == name.camelize }
            raise DuplicateMigrationNameError.new(name.camelize)
          end

          migration = MigrationProxy.new
          migration.name     = name.camelize
          migration.version  = version
          migration.filename = file
          klasses << migration
        end

        migrations = migrations.sort_by(&:version)
        down? ? migrations.reverse : migrations
      end
    end

    def pending_migrations
      already_migrated = migrated
      migrations.reject { |m| already_migrated.include?(m.version.to_i) }
    end

    def migrated
      @migrated_versions ||= self.class.get_all_versions(@db)
    end

    private
      def record_version_state_after_migrating(version)
        @migrated_versions ||= []
        if down?
          @migrated_versions.delete(version.to_i)
          @migrations_doc['versions'].delete(version)
          @db.save_doc(@migrations_doc)
        else
          @migrated_versions.push(version.to_i).sort!
          @migrations_doc['versions'] ||= []
          @migrations_doc['versions'].push(version)
          @db.save_doc(@migrations_doc)
        end
      end

      def up?
        @direction == :up
      end

      def down?
        @direction == :down
      end
  end
end