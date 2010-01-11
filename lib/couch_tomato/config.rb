require 'pp'

module CouchTomato
  class Config
    @config = {
      "couchdb_address"   => '127.0.0.1',
      "couchdb_port"      => 5984,
      "couchdb_basename"  => '',
      "couchdb_suffix"    => ''
    }
    
    @loaded = false
    def self.set_config_yml(path=nil)
      unless @loaded && path
        if (Rails rescue nil)
          path = "#{Rails.root}/config/couch_tomato.yml"
        else
          Dir.chdir(ENV['PWD'])
          until Dir.pwd == '/'
            unless (path = Dir['couch_tomato.yml'] + Dir['config/couch_tomato.yml']).empty?
              path = "#{Dir.pwd}/#{path.join}"
              break
            end
            Dir.chdir('..')
          end
          raise "A path the the configuration file was not specified. Please set the values manually." if (path.nil? || path.empty?)
        end
      end

      @config.merge!(YAML.load_file(
        "#{path}") [ENV["RAILS_ENV"] || "defaults"] || {}) if File.exist? path
      @config['couchdb_suffix'] = (ENV["RAILS_ENV"] || '') if @config['couchdb_suffix'].empty?
      @loaded = true
    end
    
    def self.couch_address=(address)
      @config["couchdb_address"] = address
    end
    
    def self.couch_port=(port)
      @config["couchdb_port"] = port.to_i
    end
    
    def self.couch_basename=(basename)
      @config["couchdb_basename"] = basename
    end
    
    def self.couch_suffix=(suffix)
      @config["couchdb_suffix"] = suffix
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
    
    def self.couch_suffix
      @config["couchdb_suffix"]
    end
    
    def self.loaded?
      @loaded
    end
  end
end
