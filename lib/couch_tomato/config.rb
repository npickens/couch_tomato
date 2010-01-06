module CouchTomato
  class Config
    @config = {
      "couchdb_address"   => '127.0.0.1',
      "couchdb_port"      => 5984,
      "couchdb_basename"  => ''
    }
    
    def self.set_config_yml(path=nil)
      begin
        path = "#{Rails.root}/config/couch_tomato.yml" if path.nil?
      rescue
        puts "A path was not specified for a config file, a default rails enviornment cannot found."
      end
      
      @config.merge! ConfigHash.new(YAML.load_file(
        "#{Rails.root}/config/couch_tomato.yml")[ENV["RAILS_ENV"]] || {}) if File.exist? path
    end
    
    def self.couch_address=(address)
      @config["couchdb_address"] = address
    end
    
    def self.couch_port=(port)
      @config["couchdb_port"] = port
    end
    
    def self.couch_basename=(basename)
      @config["couchdb_basename"] = basename
    end
    
    def self.couch_address
      @config["couchdb_address"]
    end
    
    def self.couch_port
      @config["couchdb_port"]
    end
    
    def self.couch_basename
      @config["couchdb_basename"]
    end
  end
end
