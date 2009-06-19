require 'rubygems'
require 'spec'

$:.unshift(File.dirname(__FILE__) + '/../lib')
alias :doing :lambda

require 'couch_potato'
require File.dirname(__FILE__) + "/comment"

CouchPotato::Config.database_name = 'couch_potato_test'
CouchPotato::Config.database_server = 'http://127.0.0.1:5984/'


def recreate_db
  CouchPotato.couchrest_database.delete! rescue nil
  CouchPotato.couchrest_database.server.create_db CouchPotato::Config.database_name
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
