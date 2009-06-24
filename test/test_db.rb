require File.dirname(__FILE__) + '/../lib/couch_potato.rb'

class TestDb < CouchPotato::Database
  
  class StoreItem
    include CouchPotato::Persistence

    # create the fields of the document.
    # Make sure that the keys in the hashes are
    # exactly as you want them to be in the database
    property :item
    property :prices

    # Validate the presence of the item name
    validates_presence_of :item

    # Callbacks. Supported callbacks are:
    #  :before_validation_on_update, :before_validation_on_save, 
    # :before_create, :after_create, :before_update, :after_update, 
    # :before_save, :after_save, :before_destroy, :after_destroy.
    before_create :do_before_create
    after_create  :do_after_create
  
    def do_before_create
      puts "Called before create"
    end
  
    def do_after_create
      puts "After create"
    end

  end

  # prefix :prefix    
  name :'hello-world'
  server 'http://127.0.0.1:5984/'  #Database gets instatiated here


  # todo: specify db=>host mapping in yaml, and allow to differ per environment (default to http://localhost:5184)
  view :complete, :view_name => "all", :model => StoreItem, :limit => 10 
  view :recent, :limit => 10,  :model => StoreItem, :design_doc => 'lazy' 
  
  # with_model Purchase do |x|
  #   x.view :all
  #   x.view :recent, :limit => 10
  # end
  # TestDb.purchases.all
  # TestDb.purchases.recent

end


# TestDb.query_view(:complete, {:limit => 1})

# TestDb.query_view(:recent, {:model => InternationalPurchase, :limit => 1})
         
# TestDb.query_view(:recent, :limit => 10, :key => "Monday")

