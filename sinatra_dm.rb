# Sample Sinatra app with DataMapper
# Based on http://sinatra-book.gittr.com/ DataMapper example
require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
Bundler.require

#-------------------------------------------------------------------------------

if ENV['VCAP_SERVICES'].nil?
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/blog.db")
else
  require 'json'
  svcs = JSON.parse ENV['VCAP_SERVICES']
  mysql = svcs.detect { |k,v| k =~ /^mysql/ }.last.first
  creds = mysql['credentials']
  user, pass, host, name = %w(user password host name).map { |key| creds[key] }
  DataMapper.setup(:default, "mysql://#{user}:#{pass}@#{host}/#{name}")
end

#===============================================================================

class Post
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :body, Text
  property :attachment, String
  property :created_at, DateTime

  has n, :comments
end

class Comment
  include DataMapper::Resource
  property :id, Serial
  property :body, Text
  property :created_at, DateTime
  belongs_to :post
end

DataMapper.finalize
Post.auto_upgrade!
Comment.auto_upgrade!


get '/' do
  @posts = Post.all(:order => [:id.desc], :limit => 20)
  erb :index
end

get '/post/new' do
  erb :new
end

get '/post/:id' do
  @post = Post.get(params[:id])
  erb :post
end

post '/post/create' do
  post = Post.new(:title => params[:title], :body => params[:body])

  if params[:attachment]
    file_name = params['attachment'][:filename]
    File.open('uploads/attachments/' + file_name, 'w') do |f|
      f.write(params['attachment'][:tempfile].read)
    end
    post.attachment = file_name
  end

  if post.save
    status 201
    redirect "/post/#{post.id}"
  else
    status 412
    redirect '/'
  end
end

get '/post/:id/attachment/download' do |post_id|
  file_name = Post.get(post_id).attachment
  send_file File.open('uploads/attachments/' + file_name)
  #redirect "/post/#{post.id}/#{file_name}"
end

get '/post/edit/:id' do |post_id|
  @post = Post.get(post_id)
  erb :edit
end

post '/post/update' do
  post = Post.get(params[:id])
  post.title = params[:title]
  post.body = params[:body]

  if params['attachment']
    file_name = params['attachment'][:filename]
    File.open('uploads/attachments/' + file_name, 'w') do |f|
      f.write(params['attachment'][:tempfile].read)
    end
    post.attachment = file_name
  end

  if post.save
    status 201
    redirect "/post/#{post.id}"
  else
    status 412
    redirect "/post/edit/#{post.id}"
  end
end

post '/post/upload' do
  File.open('uploads/' + params['myfile'][:filename], 'w') do |f|
    f.write(params['myfile'][:tempfile].read)
  end
  return 'The file was successfully uploaded!'
end

post '/post/:id/comments/create' do |post_id|
  blog_post = Post.get(post_id.to_i)
  comment = Comment.new(:body => params['body'], :post => blog_post)
  if comment.save
    status 201
  else
    status 412
  end
  redirect "/post/#{post_id}"
end

get '/post/:post_id/comments/delete/:comment_id' do |post_id, comment_id|
  comment = Comment.get(comment_id)
  comment.destroy
  redirect "/post/#{post_id}"
end


__END__
