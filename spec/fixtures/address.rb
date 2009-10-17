class Address
  include CouchTomato::Persistence
  
  property :street
  property :city
  property :state
  property :zip
  property :country
end