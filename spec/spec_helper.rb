require 'rubygems'
require 'spec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
alias :doing :lambda

require 'couch_tomato'
require File.dirname(__FILE__) + "/comment"

CouchTomato::Config.database_name = 'couch_tomato_test'
CouchTomato::Config.database_server = 'http://127.0.0.1:5984/'


def recreate_db
  CouchTomato.couchrest_database.delete! rescue nil
  CouchTomato.couchrest_database.server.create_db CouchTomato::Config.database_name
end
recreate_db

Spec::Matchers.define :string_matching do |regex|
  match do |string|
    string =~ regex
  end
end

def reload_test_class (class_name)
  Object.class_eval do
    if const_defined? class_name
      remove_const class_name
    end
  end
  
  file_name = class_name.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  
  load File.dirname(__FILE__) + "/#{file_name}.rb"
end
