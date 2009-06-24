# require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/test_db'
require File.dirname(__FILE__) + '/../lib/couch_potato.rb'


class SampleTest < Test::Unit::TestCase
  context "A Database class" do
    setup do 

    end
    
    should "have a database name" do
      assert_equal TestDb.database_name, 'hello-world'
    end
    
    should "have a server" do
      assert_equal TestDb.database_server, 'http://127.0.0.1:5984/'
    end
    
    should "respond to view" do
      assert_respond_to TestDb, :view
    end
    
    context "with defined views" do
      
      should "have a design document with name of the database" do
        assert TestDb.design_docs[:'hello-world']
      end
      
    end
    
    
  end
  
end
