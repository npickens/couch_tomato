require File.dirname(__FILE__) + '/spec_helper'

describe "create" do
  before(:all) do
    recreate_db
  end
  
  before(:each) do
    @comment = Comment.new :title => 'my_title'
    CouchTomato.database.save_document! @comment
  end
  
  it "should update the revision" do
    old_rev = @comment._rev
    @comment.title = 'xyz'
    CouchTomato.database.save_document! @comment
    @comment._rev.should_not == old_rev
    @comment._rev.should_not be_nil
  end
  
  it "should not update created at" do
    old_created_at = @comment.created_at
    @comment.title = 'xyz'
    CouchTomato.database.save_document! @comment
    @comment.created_at.should == old_created_at
  end
  
  it "should update updated at" do
    old_updated_at = @comment.updated_at
    @comment.title = 'xyz'
    CouchTomato.database.save_document! @comment
    @comment.updated_at.should > old_updated_at
  end
  
  it "should update the attributes" do
    @comment.title = 'new title'
    CouchTomato.database.save_document! @comment
    CouchTomato.couchrest_database.get("#{@comment.id}")['title'].should == 'new title'
  end
end