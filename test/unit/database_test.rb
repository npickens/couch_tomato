require File.dirname(__FILE__) + '/../test_helper'

class DbTestUser
end

class DatabaseTest < Test::Unit::TestCase
  
  context 'new' do
    should "raise an exception if the database doesn't exist" do
      assert_raise NameError do
        CouchPotato::Database.new CouchRest.database('couch_potato_invalid')
      end
    end
  end
  
  # context 'load' do
  #   should 'raise an exception if nil given' do
  #     object = Object.new
  #     stub(object).info {nil}
  #     db = CouchPotato::Database.new(object)
  #    
  #     assert_raise RuntimeError do
  #       db.load nil
  #     end
  #    end
  #  end
   
   context "Model's reference to database" do
     setup do
       @couchrest_db = Object.new
       stub(@couchrest_db).info {nil}
       
       @db = CouchPotato::Database.new(@couchrest_db)
       
       mock(@user = Object.new).database = @db
     end
     
     should 'be set on load' do      
       stub(@couchrest_db).get { {'ruby_class' => 'DbTestUser'} }
  
       stub(DbTestUser).new {@user}
       @db.load '1'
     end
     
     # should 'be set on save' do        
     #     stub(@user).new? {true}
     #     stub(@user).valid? {false}
     #     stub(@user).dirty? {true}
     #     stub(@user).run_callbacks
     #     
     #     @db.save_document @user
     #   end
   end
  
end


# class DbTestUser
# end
# 
# describe CouchPotato::Database, 'new' do
#   it "should raise an exception if the database doesn't exist" do
#     lambda {
#       CouchPotato::Database.new CouchRest.database('couch_potato_invalid')
#     }.should raise_error('Database \'couch_potato_invalid\' does not exist.')
#   end
# end
# 
# describe CouchPotato::Database, 'load' do
#   it "should raise an exception if nil given" do
#     db = CouchPotato::Database.new(stub('couchrest db', :info => nil))
#     lambda {
#       db.load nil
#     }.should raise_error("Can't load a document without an id (got nil)")
#   end
#   
#   it "should set itself on the model" do
#     user = mock 'user'
#     DbTestUser.stub!(:new).and_return(user)
#     db = CouchPotato::Database.new(stub('couchrest db', :info => nil, :get => {'ruby_class' => 'DbTestUser'}))
#     user.should_receive(:database=).with(db)
#     db.load '1'
#   end
# end
# 
# describe CouchPotato::Database, 'save_document' do
#   it "should set itself on the model for a new object before doing anything else" do
#     db = CouchPotato::Database.new(stub('couchrest db', :info => nil))
#     user = stub('user', :new? => true, :valid? => false).as_null_object
#     user.should_receive(:database=).with(db)
#     db.save_document user
#   end
# end