class TestDb < CouchPotato::Database
  prefix :prefix
  name :couch_potato_test
  
  # todo: specify db=>host mapping in yaml, and allow to differ per environment (default to http://localhost:5184)
  
  # view :standard
  # view :standard, :model => Post
  # view :view_name, :design => 'lazy'
  
  # view :limited_view, :model => Post, :limit => 1
  
  # def self.view(params)
  # end
end

# TestDb.view(:standard, {:limit => 1})
# TestDb.view(:standard, {:model => NotPost, :limit => 1})

# TestDb.view(:limited_view, :limit => 10, :key => "Monday")

other_db2 = CouchPotato::Database.new(couchrest_db2)
CouchPotato.blah.view Comment.all
CouchPotato.database.save Comment.new

other_db = CouchPotato::Database.new(couchrest_db)
other_db.view Comment.all
other_db.save Comment.new

