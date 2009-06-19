require File.dirname(__FILE__) + '/spec_helper'
require File.join(File.dirname(__FILE__), 'fixtures', 'address')
require File.join(File.dirname(__FILE__), 'fixtures', 'person')

class Watch
  include CouchPotato::Persistence
  
  property :time, :type => Time
end


describe 'properties' do
  before(:all) do
    recreate_db
    reload_test_class("Comment")
  end
  
  it "should return the property names" do
    Comment.property_names.should == [:created_at, :updated_at, :title, :commenter]
  end
  
  it "should persist a string" do
    c = Comment.new :title => 'my title'
    CouchPotato.database.save_document! c
    c = CouchPotato.database.load_document c.id
    c.title.should == 'my title'
  end
  
  # Explicitly declaring `:type => String` on a property raises an exception
  # "wrong argument type String (expected Hash)" on load. The json gem defines a
  # String.json_create method that expects a hash in the form `{'raw' => [0x61,
  # 0x62]}` where `[0x61, 0x62].pack => 'ab'`
  # 
  # CouchPotato expects various `json_create` methods to accept a String (and
  # return an instance). Currently, if `:type` is not specified, the type of the
  # value is assumed to be String and `json_create` is not called.

  it "Should raise an exception if a property is of a JSON native type" do
    [Float, String, Integer, Array, Hash, Fixnum].each do |klass|
      doing {
        Comment.class_eval do
          property :name, :type => klass
        end
      }.should raise_error("#{klass} is a native JSON type, only custom types should be specified")      
    end    
  end
  
  it "should persist a number" do
    c = Comment.new :title => 3
    CouchPotato.database.save_document! c
    c = CouchPotato.database.load_document c.id
    c.title.should == 3
  end
  
  it "should persist a hash" do
    c = Comment.new :title => {'key' => 'value'}
    CouchPotato.database.save_document! c
    c = CouchPotato.database.load_document c.id
    c.title.should == {'key' => 'value'}
  end
  
  it "should persist a Time object" do
    w = Watch.new :time => Time.now
    CouchPotato.database.save_document! w
    w = CouchPotato.database.load_document w.id
    w.time.year.should == Time.now.year
  end
  
  it "should persist an object" do
    p = Person.new :name => 'Bob'
    a = Address.new :city => 'Denver'
    p.ship_address = a
    CouchPotato.database.save_document! p
    p = CouchPotato.database.load_document p.id
    p.ship_address.should === a
  end
  
  it "should persist null for a null " do
    p = Person.new :name => 'Bob'
    p.ship_address = nil
    CouchPotato.database.save_document! p
    p = CouchPotato.database.load_document p.id
    p.ship_address.should be_nil
  end
  
  describe "predicate" do
    it "should return true if property set" do
      Comment.new(:title => 'title').title?.should be_true
    end
    
    it "should return false if property nil" do
      Comment.new.title?.should be_false
    end
    
    it "should return false if property false" do
      Comment.new(:title => false).title?.should be_false
    end
    
    it "should return false if property blank" do
      Comment.new(:title => '').title?.should be_false
    end
  end
end