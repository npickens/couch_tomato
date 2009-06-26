require File.dirname(__FILE__) + '/../test_helper'

module CouchRest
end

class DbTestUser
end

reload_test_db_class (TestDb)

class CustomDatabaseTest < Test::Unit::TestCase

  context 'class' do
    setup do
      reload_test_db_class
    end
    
    should "have correct database name" do
      assert_equal TestDb.database_name, :couch_potato_test
    end
    
    should "have correct prefix" do
      assert_equal TestDb.database_prefix, :prefix
    end
    
    should "have correct database url" do
      assert_equal TestDb.full_url_to_database, 'http://127.0.0.1:5984/couch_potato_test'
    end
    
    should "have correct couchrest_database" do
      db = Object.new
      mock(CouchRest).database('http://127.0.0.1:5984/couch_potato_test') { db }
      assert_equal db, TestDb.couchrest_database
    end
    
    should "have database of correct type" do
      stub(db = Object.new).info
      mock(TestDb).couchrest_database { db }
      
      assert_kind_of TestDb, TestDb.database
    end
    
    should "have correct database" do
      db = Object.new
      mock(TestDb).new(anything) { db }
      
      assert_equal db, TestDb.database
    end
    
    should "define a view" do
      mock.proxy(TestDb).view(anything)
      
      TestDb.class_eval do
        view :standard
      end
      
      assert_received(TestDb) {|klass| klass.view(:standard)}
      # assert_received(CouchPotato::Database) {|klass| klass.view(:standard)}
    end
    
    should "" do
      TestDb.class_eval do
        view :standard
      end

    end
    
  end
end