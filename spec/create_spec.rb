require File.dirname(__FILE__) + '/spec_helper'

describe "create" do
  before(:all) do
    recreate_db
  end
  describe "succeeds" do
    it "should store the class" do
      @comment = Comment.new :title => 'my_title'
      CouchTomato.database.save_document! @comment
      CouchTomato.couchrest_database.get(@comment.id)['ruby_class'].should == 'Comment'
    end
  end
  describe "fails" do
    it "should not store anything" do
      @comment = Comment.new
      CouchTomato.database.save_document @comment
      CouchTomato.couchrest_database.documents['rows'].should be_empty
    end
  end
end

