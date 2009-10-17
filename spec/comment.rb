class Comment
  include CouchTomato::Persistence

  validates_presence_of :title

  property :title
  belongs_to :commenter
end