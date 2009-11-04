module CouchTomato
  class Migration
    class << self
      # Execute this migration in the named direction
      def migrate(direction, db)
        return unless respond_to?(direction)

        write db.name
        case direction
          when :up   then announce "migrating"
          when :down then announce "reverting"
        end

        time = Benchmark.measure do
          rows = db.get('_all_docs', :include_docs => true)['rows']
          docs = []
          rows.each do |row|
            next if row['id'] =~ /^_design/
            send(direction, row['doc'])
            docs << row['doc']
          end
          db.bulk_save(docs)
        end

        case direction
          when :up   then announce "migrated (%.4fs)" % time.real; write
          when :down then announce "reverted (%.4fs)" % time.real; write
        end
      end

      def write(text="")
        puts(text)
      end

      def announce(message)
        text = "#{@version} #{name}: #{message}"
        length = [0, 75 - text.length].max
        write "== %s %s" % [text, "=" * length]
      end

      def say(message, subitem=false)
        write "#{subitem ? "   ->" : "--"} #{message}"
      end

      def say_with_time(message)
        say(message)
        result = nil
        time = Benchmark.measure { result = yield }
        say "%.4fs" % time.real, :subitem
        say("#{result} rows", :subitem) if result.is_a?(Integer)
        result
      end
    end
  end
end
