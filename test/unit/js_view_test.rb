require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/couch_potato.rb'
#require 'pp'

class JsViewTes < Test::Unit::TestCase
  context "A Javascript View class" do
    setup do
      unload_const('TestView')
      ::TestView = create_const(CouchPotato::JsViewSource)
      #unload_const('CouchDB')
      #::CouchDB = create_const(CouchRest::Database)
    end
        
    should "have a database names" do
      stub(TestView).path {"test/fixtures/fs_database/views"}
      assert_equal TestView.fs_database_names, ['offers']
    end # have db names
    
    should "be able to get database docs from couch server" do
      stub(TestView).get {{
        "rows"=>[{
          "doc"=>{
            "language"=>"javascript", 
            "_rev"=>"1-728649903", 
            "_id"=>"_design/test", 
            "views"=>{
              "test"=>{
                "map"=>"function(doc) {\n  emit(null, doc);\n}"
              }
            }
          }, 
          "id"=>"_design/test", 
          "value"=>{
            "rev"=>"1-728649903"
          }, 
          "key"=>"_design/test"
        }], 
        "offset"=>0, 
        "total_rows"=>1}
      }

      assert_equal TestView.db_design_docs(CouchRest.database(" : / ")), {
        :test=> {
          "language"=>"javascript",
          "_id"=>"_design/test",
          "_rev"=>"1-728649903",
          "views"=>{
            "test"=>{
              "map"=>"function(doc) {\n  emit(null, doc);\n}"
            }
          }
        }
      }
    end # get server docs
  end
end # class