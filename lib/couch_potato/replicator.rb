module CouchPotato
  class Replicator
    # Timeout for a single database replication (in seconds).
    READ_TIMEOUT = 86400

    def initialize(src_server, dst_server = nil)
      @src_server = CouchRest::Server.new(src_server)
      @dst_server = dst_server ? CouchRest::Server.new(dst_server) : @src_server

      @db_names = @src_server.databases
    end

    def replicate(src_db_name, dst_db_name)
      raise "Source database '#{src_db_name}' does not exist" unless @db_names.include?(src_db_name)

      @dst_server.database!(dst_db_name)

      src_uri = URI.parse(@src_server.uri)
      dst_uri = URI.parse(@dst_server.uri)

      http = Net::HTTP.new(dst_uri.host, dst_uri.port)
      http.read_timeout = READ_TIMEOUT
      http.post('/_replicate', "{\"source\": \"#{src_uri}/#{src_db_name}\", \"target\": \"#{dst_uri}/#{dst_db_name}\"}")
    end

    def replicate_all(suffix = nil)
      @db_names.each do |db_name|
        replicate(db_name, "#{db_name}#{suffix}")
      end
    end
  end
end