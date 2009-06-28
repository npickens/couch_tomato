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
    
    # should "call the required callbacks before validation" do
    #   Comment.class_eval do
    #     property :title
    #     validates_presence_of :title
    #   end
    #   
    #   @comment = Comment.new
    #   
    #   mock(@comment).
    # end
  end #context a model that will persist data
  
end