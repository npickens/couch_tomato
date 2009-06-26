require File.dirname(__FILE__) + '/../lib/couch_potato.rb'

class TestDb < CouchPotato::Database
  # 
  # class StoreItem
  #   include CouchPotato::Persistence
  # 
  #   # create the fields of the document.
  #   # Make sure that the keys in the hashes are
  #   # exactly as you want them to be in the database
  #   property :item
  #   property :prices
  # 
  #   # Validate the presence of the item name
  #   validates_presence_of :item
  # 
  #   # Callbacks. Supported callbacks are:
  #   #  :before_validation_on_update, :before_validation_on_save, 
  #   # :before_create, :after_create, :before_update, :after_update, 
  #   # :before_save, :after_save, :before_destroy, :after_destroy.
  #   before_create :do_before_create
  #   after_create  :do_after_create
  # 
  #   def do_before_create
  #     puts "Called before create"
  #   end
  # 
  #   def do_after_create
  #     puts "After create"
  #   end
  # 
  # end
  # 
  # # you could specify a prefix if so desired
  # # prefix :prefix    
  # name :'hello-world'
  # server 'http://127.0.0.1:5984/'  #Database gets instatiated here
  # view :complete, :view_name => 'all', :model => StoreItem, :limit => 10 
  # view :cmplt_hash, :view_name => 'all', :model=> :raw, :limit => 10
  # view :cmplt_use_doc_model, :view_name => 'all', :design_doc => 'hello-world'
  
end

