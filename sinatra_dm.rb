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

get '/post/:id/edit' do |post_id|
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
  if params[:body].length > 0
    blog_post = Post.get(post_id.to_i)
    comment = Comment.new(:body => params['body'], :post => blog_post)
    if comment.save
      status 201
    else
      status 412
    end
  end
  redirect "/post/#{post_id}"
end

get '/post/:post_id/comments/delete/:comment_id' do |post_id, comment_id|
  comment = Comment.get(comment_id)
  comment.destroy
  redirect "/post/#{post_id}"
end


__END__

@@layout
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <title>Bootstrap 101 Template</title>

    <!-- Bootstrap -->
    <link href="/css/bootstrap.min.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://oss.maxcdn.com/html5shiv/3.7.2/html5shiv.min.js"></script>
      <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
    <![endif]-->
  </head>
  <body>
    <div class="container">
      <%= yield %>
    </div>



    <!-- comment added just for resting -->
    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <!-- <script src="/js/bootstrap.min.js"></script> -->
  </body>
</html>

