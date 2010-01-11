require 'couchrest'
require 'json'
require 'json/add/core'
require 'json/add/rails'
require 'active_support'

# require 'ostruct'


module CouchTomato
  # Config = OpenStruct.new

  # Returns a database instance which you can then use to create objects and query views. 
  # You have to set the CouchTomato::Config.database_name before this works.

  # def self.database
  #   @@__database ||= Database.new(self.couchrest_database)
  # end

  # Returns the underlying CouchRest database object if you want low level access to your CouchDB. 
  # You have to set the CouchTomato::Config.database_name before this works.
  # def self.couchrest_database
  #   @@__couchrest_database ||= CouchRest.database(full_url_to_database)
  # end

  # private

  # def self.full_url_to_database
  #   raise('No Database configured. Set CouchTomato::Config.database_name') unless CouchTomato::Config.database_name
  #   if CouchTomato::Config.database_server
  #     return "#{CouchTomato::Config.database_server}#{CouchTomato::Config.database_name}"
  #   else
  #     return "http://127.0.0.1:5984/#{CouchTomato::Config.database_name}"
  #   end
  # end
end

require File.dirname(__FILE__) + '/core_ext/object'
require File.dirname(__FILE__) + '/core_ext/time'
require File.dirname(__FILE__) + '/core_ext/date'
require File.dirname(__FILE__) + '/core_ext/string'
require File.dirname(__FILE__) + '/core_ext/symbol'
require File.dirname(__FILE__) + '/core_ext/extract_options'
require File.dirname(__FILE__) + '/core_ext/duplicable'
require File.dirname(__FILE__) + '/core_ext/inheritable_attributes'
require File.dirname(__FILE__) + '/couch_tomato/config'
require File.dirname(__FILE__) + '/couch_tomato/persistence'
require File.dirname(__FILE__) + '/couch_tomato/js_view_source'

