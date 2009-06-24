require 'rubygems'
# require 'activesupport'
require 'test/unit'
require 'shoulda'
require 'rr'

$:.unshift(File.dirname(__FILE__) + '/../lib')

require File.dirname(__FILE__) + '/../lib/couch_potato.rb'

unless Test::Unit::TestCase.include?(RR::Adapters::TestUnit)
  class Test::Unit::TestCase
    include RR::Adapters::TestUnit
  end
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
