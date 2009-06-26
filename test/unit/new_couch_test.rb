require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../test_db'
require File.dirname(__FILE__) + '/../../lib/couch_potato.rb'

class TestNewCouch < Test::Unit::TestCase
  context "A Database class" do
    setup do
      reload_test_db_class('TestDb')
    end
        
    should "have a database name" do
      TestDb.class_eval do
        name 'hello-world'
      end
      assert_equal TestDb.database_name, 'hello-world'
    end # have db name
    
    should "instatiate the couchrest database after the server is assigned" do
      
      stub(TestDb).database_name{'hello-world'}
      
      TestDb.class_eval do
        server 'http://127.0.0.1:5984/' 
      end
      assert_respond_to TestDb.couchrest_db, :info
    end #instatiate couchrest
    
    context "with a correctly configured database -- server" do
      setup do
        stub(TestDb).database_name{'hello-world'}
        stub(TestDb).database_server{'http://127.0.0.1:5984/'}
      end
    
      should "raise an exception if no nemonic is given for the view" do
        assert_raise ArgumentError do
          TestDb.class_eval do
            view
          end
        end 
      end # raise an exception
      
      should "use nemonic name for view name if none is given" do
        TestDb.class_eval do
          view :hello
        end 
        assert_equal TestDb.views[:hello][:view_name], 'hello'
      end #should have data from view

      should "use database name for design doc name if none is given" do
        TestDb.class_eval do
          view :hello
        end 
        assert_equal TestDb.views[:hello][:design_doc].to_s, 'hello-world'
      end #should have data from view
      
      context "if given a document to save with a certain class" do
        setup do
          @document = Object.new
          stub(@document).dirty?{1}   
        end

        should "call create_doc if the document is new" do               
          stub(@document).new?{1}     
          stub(TestDb).create_document {true}   
          dont_allow(TestDb).update_document(@document)
          assert_equal TestDb.save_document(@document), true    
        end
                 
        should "call update_doc if the document is not new" do               
          stub(@document).new?{nil}     
          stub(TestDb).update_document {true}   
          dont_allow(TestDb).create_document(@document)
          assert_equal TestDb.save_document(@document), true    
        end
        
      end
      
                
    end # context with db and serv
  end #context a Db  
end # class


    # should "have a server" do
    #   assert_equal TestDb.database_server, 'http://127.0.0.1:5984/'
    # end
    # 
    # should "respond to prefix" do
    #   assert_respond_to TestDb, :prefix
    # end
    # 
    # should "respond to view" do
    #   assert_respond_to TestDb, :view
    # end
    # 
    # context "with defined views" do
    #   
    #   should "have a design document with name of the database" do
    #     assert TestDb.views
    #   end
    #   
    # end
