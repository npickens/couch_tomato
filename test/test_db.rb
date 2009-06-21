class TestDb < CouchPotato::Database
  prefix :prefix
  name :couch_potato_test
  
  # todo: specify db=>host mapping in yaml, and allow to differ per environment (default to http://localhost:5184)
  
  view :complete, :name => "all", :model => Purchase 
  view :recent, :name => "all", :limit => 10,  :model => Purchase, :design => 'lazy' 
  
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

