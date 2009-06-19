class Comment
  include CouchPotato::Persistence

  validates_presence_of :title

  property :title
  belongs_to :commenter
end