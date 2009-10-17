require File.dirname(__FILE__) + '/../spec_helper'

class DbTestUser
end

describe CouchTomato::Database, 'new' do
  it "should raise an exception if the database doesn't exist" do
    lambda {
      CouchTomato::Database.new CouchRest.database('couch_tomato_invalid')
    }.should raise_error('Database \'couch_tomato_invalid\' does not exist.')
  end
end

describe CouchTomato::Database, 'load' do
  it "should raise an exception if nil given" do
    db = CouchTomato::Database.new(stub('couchrest db', :info => nil))
    lambda {
      db.load nil
    }.should raise_error("Can't load a document without an id (got nil)")
  end
  
  it "should set itself on the model" do
    user = mock 'user'
    DbTestUser.stub!(:new).and_return(user)
    db = CouchTomato::Database.new(stub('couchrest db', :info => nil, :get => {'ruby_class' => 'DbTestUser'}))
    user.should_receive(:database=).with(db)
    db.load '1'
  end
end

describe CouchTomato::Database, 'save_document' do
  it "should set itself on the model for a new object before doing anything else" do
    db = CouchTomato::Database.new(stub('couchrest db', :info => nil))
    user = stub('user', :new? => true, :valid? => false).as_null_object
    user.should_receive(:database=).with(db)
    db.save_document user
  end
end