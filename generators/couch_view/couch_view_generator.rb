class CouchViewGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      db_name = args.shift
      full_view_name = args.shift

      design_doc = full_view_name.index('/') ? full_view_name.split('/').first : nil
      view_name = full_view_name.split('/').last

      # should only contain map, reduce, or be empty (only map)
      bad_option = false
      if args.empty?
        args << 'map'
      else
        args.each do |arg|
          if arg != 'map' && arg != 'reduce'
            puts "Invalid option '#{arg}': expecting 'map' and/or 'reduce'"
            bad_option = true
          end
        end

        next if bad_option
      end

      dir = File.join(['couchdb', 'views', db_name, design_doc].compact)

      m.directory(dir)
      args.each do |method|
        m.file("#{method}.js", File.join(dir, "#{view_name}-#{method}.js"), :collision => :ask)
      end
    end
  end
end
