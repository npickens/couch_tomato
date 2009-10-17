class Person
  include CouchTomato::Persistence
  
  property :name
  property :ship_address, :type => Address
end