class Post
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :body, Text
  property :attachment, String
  property :created_at, DateTime

  has n, :comments
end