require File.dirname(__FILE__) + '/../spec_helper'

describe CouchTomato::View::CustomViews do
  
  class MyViewSpec; end
  class ModelWithView
    include CouchTomato::Persistence
    view :all, :type => MyViewSpec
  end
  
  it "should use a custom viewspec class" do
    MyViewSpec.should_receive(:new)
    ModelWithView.all
  end
end