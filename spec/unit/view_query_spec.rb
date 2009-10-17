require File.dirname(__FILE__) + '/../spec_helper'

describe CouchTomato::View::ViewQuery, 'query_view' do
  it "should not pass a key if conditions are empty" do
    db = mock 'db'
    db.should_receive(:view).with(anything, {})
    CouchTomato::View::ViewQuery.new(db, '', '', '', '').query_view!
  end
end