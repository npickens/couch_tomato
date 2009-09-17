require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/couch_potato.rb'

module Foo
  class Bar
  end
end

class DatabaseTes < Test::Unit::TestCase
  context "A Database class" do
    setup do
      unload_const('TestDb')
      ::TestDb = create_const(CouchPotato::Database)
    end
        
    should "have a database name" do
      TestDb.class_eval do
        name 'hello-world'
      end
      assert_equal TestDb.database_name, 'hello-world'
    end # have db name
    
    should "assign the localhost as server if none is given" do
      @db =  Object.new
      stub(TestDb).database_name{'hello-world'}
      stub(TestDb).database{@db}
      stub(@db).info{1}
      
      TestDb.class_eval do
        server 
      end
      assert_equal TestDb.database_server, 'http://127.0.0.1:5984/'
    end #instatiate couchrest
    
    should "raise an exception if the database doesn't exist" do
      assert_raise RestClient::RequestFailed do
        TestDb.class_eval do
          name 'DoesNotExist'
          server
        end
      end
    end
    
    context "with a correctly configured database and server" do
      setup do
        stub(TestDb).database_name{'hello-world'}
        stub(TestDb).database_server{'http://127.0.0.1:5984/'}
        stub(TestDb.database).info{1}
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
      
      context "if given a document to save" do
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
        
        context ", " do
          setup do
            stub(@document).valid?{1}
            stub(@document).to_hash{1}

            stub(TestDb.database).save_doc{{'rev' => '1', 'id' => '123', }}
            stub(@document)._rev=('1')
            
            mock(@document).run_callbacks(:before_validation_on_save)
            mock(@document).run_callbacks(:before_save)
            mock(@document).run_callbacks(:after_save)
          end

          should ", if the document is new, call the required callbacks before saving it" do
            stub(@document).new?{1}                        

            stub(@document).database=(TestDb)
            stub(@document)._id=('123') 
          
            mock(@document).run_callbacks(:before_validation_on_create)
            mock(@document).run_callbacks(:before_create)
            mock(@document).run_callbacks(:after_create)
          
            assert_equal TestDb.save_document(@document), true
          end
          
          should ", if the document is not new, call the required callbacks before saving it" do
            stub(@document).new?{nil}               
 
            mock(@document).run_callbacks(:before_validation_on_update)
            mock(@document).run_callbacks(:before_update)
            mock(@document).run_callbacks(:after_update)
          
            assert_equal TestDb.save_document(@document), true
          end          
        end # context ,
      end #context if given a doc to save
      
      context "if loading a document" do
        setup do
          
        end

        should "raise an exception if no id is given" do
          assert_raise ArgumentError do
            TestDb.load_doc
          end 
        end
        
        should "raise an exception if a nil id is given" do
          assert_raise RuntimeError do
            TestDb.load_doc nil
          end 
        end
        
        should "return nil if no document matching the given id is found" do
          stub(TestDb.database).get('123456789'){raise RestClient::ResourceNotFound}
          document = TestDb.load_doc '123456789'
          assert_equal document, nil
        end

        should "return a hash if :model => :raw is given as an option" do
          stub(TestDb.database).get('123456789'){{:key => "value", :key2 => "value2", }}
          document = TestDb.load_doc '123456789', :model => :raw
          assert_equal document, {:key => "value", :key2 => "value2", }
        end
        
        should "return a hash if the document does not specify a class" do
          stub(TestDb.database).get('123456789'){{:key => "value", :key2 => "value2", }}
          document = TestDb.load_doc '123456789'
          assert_equal document, {:key => "value", :key2 => "value2", }
        end
        
        should "return the right class of object if one is specified in the document" do
          stub(TestDb.database).get('123456789'){{'ruby_class' => 'Object', :key2 => "value2", }}
          document = TestDb.load_doc '123456789'
          # document = TestDb.load_doc '123456789', :model => Object
          
          assert_equal document.class, Object
        end
        
        should "find classes namespeced within other classes" do
          stub(TestDb.database).get('123456789'){{'ruby_class' => 'Foo::Bar', :key2 => "value2", }}
          document = TestDb.load_doc '123456789'
          
          assert_equal document.class, Foo::Bar
        end
      end #context loading document
      
      context "if querying a view" do
        setup do
          
        end

        should "raise an exception if the view is not found in the DB class" do
          #  self.query_view(name, options.merge(self.views[name][:couch_options]))
          assert_raise RuntimeError do
            TestDb.query_view!(:query_name)
          end
        end
        
        should "raise an exception if the view is not found in the database" do
          stub(TestDb).query_view(:query_name,{}){raise RestClient::ResourceNotFound}
          stub(TestDb).views{{:query_name => "query_name"}}
          
          assert_raise RestClient::ResourceNotFound do
            TestDb.query_view!(:query_name)
          end
          
        end
        
        context "the results" do
          setup do
            @fields = {:"key" => "value", :"key2" => "value2"}
            @fields2 = {:"key3" => "value3", :"key4" => "value4"}
            
            @row1 = {"id" => "123456789", "value" => @fields, "key" => "7654321"}
            @row2 = {"id" => "987654321", "value" => @fields2, "key" => "1234567"}
          end

           should "return an array of hashes if the documents do not cotain Class info" do
            stub(TestDb).query_view(:query_name,{}){{"rows" => [@row1, @row2], "offset" => 0, "total_rows" => 2 }}
            stub(TestDb).views{{:query_name => {:anything => "query_name"}}}
          
            assert_equal TestDb.query_view!(:query_name), [@fields, @fields2]
          end
          
          should "find classes namespeced within other classes"
          
          should "return an empty array if results is empty" do
            stub(TestDb).views{{:query_name => {:anything => "query_name"}}}
            
            empty_results = {"rows" => [], "offset" => 0, "total_rows" => 2 }
            assert_equal TestDb.process_results(:query_name, empty_results), []
          end
          
          should "return an array of hashes if the documents cotain Class info but the user specified :model=> :raw" do
            @fields.merge!({"ruby_class" => "Object"})
            @fields2.merge!({"ruby_class" => "Object"})
          
            stub(TestDb).query_view(:query_name,{:model => :raw}){{"rows" => [@row1, @row2], "offset" => 0, "total_rows" => 2 }}
            stub(TestDb).views{{:query_name => {:anything => "query_name"}}}
          
            assert_equal TestDb.query_view!(:query_name, :model => :raw ), [@fields, @fields2]
          
          end
        
          should "return an array of Objects if the view definition specified :model=> Object" do
            @fields.merge!({"ruby_class" => "Object"})
            @fields2.merge!({"ruby_class" => "Object"})

            stub(TestDb).query_view(:query_name,{}){{"rows" => [@row1, @row2], "offset" => 0, "total_rows" => 2 }}
            stub(TestDb).views{{:query_name => {:model => Object}}}
            stub(Object).json_create(@fields, {"id"=>"123456789", "key"=>"7654321"}){Object.new}
            stub(Object).json_create(@fields2, {"id"=>"987654321", "key"=>"1234567"}){Object.new}
            
          
            assert_equal TestDb.query_view!(:query_name, {})[0].class, Object
            assert_equal TestDb.query_view!(:query_name, {})[1].class, Object
          end
          
          should "return an array of Objects if the view definition did not specify :model=> Object but the docs contain 'ruby_class' info" do
            @fields.merge!({"ruby_class" => "Object"})
            @fields2.merge!({"ruby_class" => "Object"})
          
            stub(TestDb).query_view(:query_name,{}){{"rows" => [@row1, @row2], "offset" => 0, "total_rows" => 2 }}
            stub(TestDb).views{{:query_name => {:anything => "query_name"}}}
            stub(Object).json_create(@fields, {"id"=>"123456789", "key"=>"7654321"}){Object.new}
            stub(Object).json_create(@fields2, {"id"=>"987654321", "key"=>"1234567"}){Object.new}
          
            assert_equal TestDb.query_view!(:query_name, {})[0].class, Object
            assert_equal TestDb.query_view!(:query_name, {})[1].class, Object
          
          end          
          
          should "return an mixed array of Objects and hashes if the view definition did not specify :model=> Object but some docs contain 'ruby_class' info" do
            @fields.merge!({"ruby_class" => "Object"})

            stub(TestDb).query_view(:query_name,{}){{"rows" => [@row1, @row2], "offset" => 0, "total_rows" => 2 }}
            stub(TestDb).views{{:query_name => {:anything => "query_name"}}}
            stub(Object).json_create(@fields, {"id"=>"123456789", "key"=>"7654321"}){Object.new}
            stub(Hash).json_create(@fields2, {"id"=>"987654321", "key"=>"1234567"}){Object.new}
          
            assert_equal TestDb.query_view!(:query_name, {})[0].class, Object
            assert_equal TestDb.query_view!(:query_name, {})[1].class, Hash
          
          end
        end # context the results          
      end # context querying a view
    end # context with db and serv
  end #context a Db  
end # class