class TestDb < CouchPotato::Database
  prefix :prefix
  name :couch_potato_test
  
  # todo: specify db=>host mapping in yaml, and allow to differ per environment (default to http://localhost:5184)
  
  # view :standard
  # view :standard, :model => Post
  # view :view_name, :design => 'lazy'
  
  # def self.view(params)
  # end
end

# TestDb.view(:standard, {:limit => 1})
# TestDb.view(:standard, {:model => NotPost, :limit => 1})