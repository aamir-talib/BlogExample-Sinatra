class Comment
  include DataMapper::Resource
  property :id, Serial
  property :body, Text
  property :created_at, DateTime
  belongs_to :post
end