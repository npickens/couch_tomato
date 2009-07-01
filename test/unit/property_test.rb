require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../../lib/couch_potato.rb'

class PropertyTes < Test::Unit::TestCase
  context "A Model that will persist data using CouchPotato" do
    setup do
      unload_const('Comment')
      ::Comment = create_const 
      Comment.class_eval do
        include CouchPotato::Persistence
      end     
    end

    should "raise an exception if native JSON data types are assigned to the properties" do
      [Float, String, Integer, Array, Hash, Fixnum].each do |klass|
        assert_raise RuntimeError do
          Comment.class_eval do
            property :title, :type => klass
          end
        end      
      end    
    end
    
    should "return the names of its properties using property_names" do
      Comment.class_eval do
        property :title
        property :commenter
        property :email
      end
      assert_equal Comment.property_names, [:created_at, :updated_at, :title, :commenter, :email]
    end
    
    should "respond to property name attribute accessor methods" do
      Comment.class_eval do
        property :title
      end
      
      @comment = Comment.new
      
      assert  @comment.respond_to?(:title)
      assert  @comment.respond_to?(:title=)
    end
    
    should "mark as invalid a property which requires to have a value and has none" do
      Comment.class_eval do
        property :title
        validates_presence_of :title
      end
      
      @comment = Comment.new
      
      assert_equal @comment.valid?, false
      
      @comment.title = "Title"
      
      assert_equal @comment.valid?, true
    end
    
    should "call the validate callbacks when required" do
      Comment.class_eval do
        property :title
        validates_presence_of :title
      end
      
      @comment = Comment.new :title => "My Title"
      
      # stub(@comment).valid?{true}
      mock(@comment).run_callbacks(:before_validation)
      
      @comment.valid?
    end
    
    should "return true if a property is set" do
      Comment.class_eval do
        property :title
      end

      @comment = Comment.new
      
      assert_equal @comment.title?, false
      
      @comment.title = "Title"
      
      assert_equal @comment.title?, true
    end
    
    context "and has callback methods defined" do
      setup do
        Comment.class_eval do
            property :title
            
            before_create :do_before
            after_create  :do_after
            
            attr_reader :count_var
              
            def do_before
              @count_var = 0
              @count_var +=3
            end

            def do_after
              @count_var +=2
            end
            
        end
        
          unload_const('TestDb')
          ::TestDb = create_const(CouchPotato::Database)
          
          @document = Comment.new :title => "My Title"
          
          stub(@document).valid?{true}
          
          stub(TestDb.couchrest_db).save_doc{{'rev' => '1', 'id' => '123'}}
          
      end
      

      should "support single callbacks" do
        stub(@document).new?{true}
        stub(@document).dirty?{true}
        
        TestDb.save_doc @document
        
        assert_equal @document.count_var, 5
      end
      
      should "support multiple callbacks" do
        stub(@document).new?{false}
        stub(@document).dirty?{true}
        
        Comment.class_eval do
            before_update :do_before, :do_after
            after_update  :do_after
        end
        
        TestDb.save_doc @document
        
        assert_equal @document.count_var, 7
      end
    end # context has callbacks defined
    
    context "and wants to delete (destroy) a particular document" do
      setup do
        unload_const('TestDb')
        ::TestDb = create_const(CouchPotato::Database)
        TestDb.couchrest_db = Object.new
          
        @document = Comment.new 
        @document._deleted = false
        @document._id = '123'
        @document._rev = '456'
        stub(@document).to_hash{1}
        stub(TestDb.couchrest_db).delete_doc(@document.to_hash) {1}
        mock(@document).run_callbacks(:before_destroy)
        mock(@document).run_callbacks(:after_destroy)
      end

      should "call the destroy related callbacks" do
        TestDb.destroy_doc(@document)
      end
      
      should "mark the document as deleted" do
        TestDb.destroy_doc(@document)
        
        assert_equal true, @document._deleted
      end

      should "make the document id nil" do
        TestDb.destroy_doc(@document)
        
        assert_equal nil, @document.id
      end

      should "make the document revision nil" do
        TestDb.destroy_doc(@document)
        
        assert_equal nil, @document._rev
      end
    end
    
  end #context a model that will persist data
  
end