require File.dirname(__FILE__) + '/../spec_helper'

class Plate
  include CouchTomato::Persistence
  
  property :food
end

describe 'dirty attribute tracking' do
  before(:each) do
    @couchrest_db = stub('database', :save_doc => {'id' => '1', 'rev' => '2'}, :info => nil)
    @db = CouchTomato::Database.new(@couchrest_db)
  end
  
  describe "save" do
    it "should not save when nothing dirty" do
      plate = Plate.new :food => 'sushi'
      @db.save_document!(plate)
      @couchrest_db.should_not_receive(:save_doc)
      @db.save_document(plate)
    end
    
    it "should return true when not dirty" do
      plate = Plate.new :food => 'sushi'
      @db.save_document!(plate)
      @db.save_document(plate).should be_true
    end
    
    it "should save when there are dirty attributes" do
      plate = Plate.new :food => 'sushi'
      @db.save_document!(plate)
      plate.food = 'burger'
      @couchrest_db.should_receive(:save_doc)
      @db.save_document(plate)
    end
  end
  
  describe "newly created object" do
    
    before(:each) do
      @plate = Plate.new :food => 'sushi'
    end
    
    describe "access old values" do
      it "should return the old value" do
        @plate.food = 'burger'
        @plate.food_was.should == 'sushi'
      end
    end

    describe "check for dirty" do
      it "should return true if attribute changed" do
        @plate.food = 'burger'
        @plate.should be_food_changed
      end

      it "should return false if attribute not changed" do
        @plate.should_not be_food_changed
      end
      
      it "should return false if attribute forced not changed" do
        @plate.food = 'burger'
        @plate.food_not_changed
        @plate.should_not be_food_changed
      end
    end
  end
  
  describe "object loaded from database" do
    before(:each) do
      couchrest_db = stub('database', :get => {'_id' => '1', '_rev' => '2', 'food' => 'sushi', 'ruby_class' => 'Plate'}, :info => nil)
      @plate = CouchTomato::Database.new(couchrest_db).load_document '1'
    end
    
    describe "access old values" do
      it "should return the old value" do
        @plate.food = 'burger'
        @plate.food_was.should == 'sushi'
      end
    end

    describe "check for dirty" do
      it "should return true if attribute changed" do
        @plate.food = 'burger'
        @plate.should be_food_changed
      end
      
      it "should return true if array attribute changed" do
        couchrest_db = stub('database', :get => {'_id' => '1', '_rev' => '2', 'food' => ['sushi'], 'ruby_class' => 'Plate'}, :info => nil)
        plate = CouchTomato::Database.new(couchrest_db).load_document '1'
        plate.food << 'burger'
        plate.should be_food_changed
      end

      it "should return false if attribute not changed" do
        @plate.should_not be_food_changed
      end
    end
  end
  
  
  describe "after save" do
    it "should reset all attributes to not dirty" do
      couchrest_db = stub('database', :get => {'_id' => '1', '_rev' => '2', 'food' => 'sushi', 'ruby_class' => 'Plate'}, :info => nil, :save_doc => {})
      db = CouchTomato::Database.new(couchrest_db)
      @plate = db.load_document '1'
      @plate.food = 'burger'
      db.save! @plate
      @plate.should_not be_food_changed
    end
  end
  
end