require 'rubygems'
# require 'activesupport'
require 'test/unit'
require 'shoulda'
require 'rr'
require 'couchrest'

$:.unshift(File.dirname(__FILE__) + '/../lib')

unless Test::Unit::TestCase.include?(RR::Adapters::TestUnit)
  class Test::Unit::TestCase
    include RR::Adapters::TestUnit
  end
end

def camelize given_string
  given_string.sub(/^([a-z])/) {$1.upcase}.gsub(/_([a-z])/) do
    $1.upcase
  end
end

# Source
# http://github.com/rails/rails/blob/b600bf2cd728c90d50cc34456c944b2dfefe8c8d/activesupport/lib/active_support/inflector.rb
def underscore given_string
  given_string.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
end

def reload_test_db_class (klass)
  Object.class_eval do
    if const_defined? klass
      remove_const klass
    end
  end
  
  load underscore(klass) +'.rb'
end



# class Test::Unit::TestCase
#   include RR::Adapters::TestUnit unless include?(RR::Adapters::TestUnit)
# end

# 3.times {puts}

# class TestDb > CouchPotato::Database
#   name 'couch_potato_test'
# end

# CouchPotato::Config.database_name = 'couch_potato_test'
# CouchPotato::Config.database_server = 'http://127.0.0.1:5984/'


# class Comment
#   include CouchPotato::Persistence
# 
#   validates_presence_of :title
# 
#   property :title
#   belongs_to :commenter
# end
# 
# def recreate_db
#   CouchPotato.couchrest_database.delete! rescue nil
#   CouchPotato.couchrest_database.server.create_db CouchPotato::Config.database_name
# end
# recreate_db
# 
# Spec::Matchers.define :string_matching do |regex|
#   match do |string|
#     string =~ regex
#   end
# end
