require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/couch_potato.rb'

class JsViewTes < Test::Unit::TestCase
  context "A Javascript View class" do
    setup do
      unload_const('TestView')
      ::TestView = create_const(CouchPotato::JsViewSource)
    end
        
    should "infer a single database name from the file system" do
      stub(TestView).path {File.dirname(__FILE__) + "/../../test/fixtures/fs_database/views"}
      assert_equal TestView.fs_database_names, ['offers']
    end
    
    should "get a single design doc from couch server" do
      mock(db = Object.new).get(anything, anything) {
        {
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
            }
          }]
        }
      }
      
      assert_equal TestView.db_design_docs(db), {
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
    end
    
    should "get a single design doc from couch server and format it regardless of uncessary included data" do
      mock(db = Object.new).get(anything, anything) {
        {
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
          "total_rows"=>1
        }
      }
      
      assert_equal TestView.db_design_docs(db), {
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
    end
    
    context "with views in the local filesystem" do
      setup do
        @path = "/Users/shoulda/couch_potato/views"
        @db_name = "offers"
        stub(TestView).path { @path + "/" + @db_name }
        
        def format_views(views, doc=nil)
          views.map do |view|
            [@path, @db_name, doc, view].compact.join("/")
          end
        end
      end
    
      should "get a hash of a design doc under a specific database with no design folders in the filesystem without a reduce" do
        views = ["view-map.js"]
        views_path = format_views(views)
      
        stub(Dir).[](TestView.path + "/**") { views_path }      
        fs_view_ret = {
          "_id"=>"_design/offers",
          "views"=> {
            "view"=> {
              "map"=>"function(doc) {\n  emit(null, doc);\n}",
              "sha1-map"=>"d98e88e9ce74299293daa529eee229bcbfc40ae2"
            }
          }}
          
        stub(TestView).fs_view {fs_view_ret}
        assert_equal TestView.fs_design_docs(@db_name), { @db_name.to_sym => fs_view_ret }
      end
      
      should "get a hash of a design doc under a specific database with no design folders in the filesystem with a reduce" do
        views = ["view-map.js", "view-reduce.js"]
        views_path = format_views(views)
      
        stub(Dir).[](TestView.path + "/**") { views_path }
        fs_view_ret = {
          "_id"=>"_design/offers",
          "views"=> {
            "view"=> {
              "sha1-reduce"=>"d98e88e9ce74299293daa529eee229bcbfc40ae2",
              "reduce"=>"function(doc) {\n  emit(null, doc);\n}",
              "map"=>"function(doc) {\n  emit(null, doc);\n}",
              "sha1-map"=>"d98e88e9ce74299293daa529eee229bcbfc40ae2"
            }
          }}
          
        stub(TestView).fs_view {fs_view_ret}
        assert_equal TestView.fs_design_docs(@db_name), { @db_name.to_sym => fs_view_ret }
      end
      
      should "raise an exception when a reduce view is given without a corresponding map view under a specific database with no design folders" do
        views = ["view-reduce.js"]
        views_path = format_views(views)
      
        stub(Dir).[](TestView.path + "/**") { views_path }
        fs_view_ret = {
          "_id"=>"_design/offers",
          "views"=> {
            "view"=> {
              "sha1-reduce"=>"d98e88e9ce74299293daa529eee229bcbfc40ae2",
              "reduce"=>"function(doc) {\n  emit(null, doc);\n}"
            }
          }}
          
        stub(TestView).fs_view {fs_view_ret}
        assert_raise RuntimeError do
          TestView.fs_design_docs(@db_name)
        end
      end

      should "get a hash of design docs under a specific database with design folders" do
        design_name = "feed_operations"
        views = ["view-map.js"]
        views_path = format_views(views, design_name)
        
        stub(Dir).[](TestView.path + "/**") { format_views([design_name]) }
        stub(Dir).[]("#{TestView.path}/#{design_name}/*.js") { views_path }
        fs_view_ret = {
          "_id"=>"_design/#{design_name}",
          "views"=> {
            "view"=> {
              "map"=>"function(doc) {\n  emit(null, doc);\n}",
              "sha1-map"=>"d98e88e9ce74299293daa529eee229bcbfc40ae2"
            }
          }}
          
        stub(TestView).fs_view {fs_view_ret}
        assert_equal TestView.fs_design_docs(@db_name), { design_name.to_sym => fs_view_ret }
      end
    end
  end
end