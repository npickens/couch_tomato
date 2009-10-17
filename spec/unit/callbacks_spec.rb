require File.dirname(__FILE__) + '/../spec_helper'

class Tree
  include CouchTomato::Persistence
  before_validation :water!
  before_validation lambda {|tree| tree.root_count += 1 }
  
  property :leaf_count
  property :root_count
  
  def water!
    self.leaf_count += 1
  end
end


describe 'before_validation callback' do
  before :each do
    @tree = Tree.new(:leaf_count => 1, :root_count => 1)
  end
  
  it "should call water! when validated" do
    @tree.leaf_count.should == 1
    @tree.should be_valid
    @tree.leaf_count.should == 2
  end
  
  it "should call lambda when validated" do
    @tree.root_count.should == 1
    @tree.should be_valid
    @tree.root_count.should == 2
  end
end
