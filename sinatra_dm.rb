# Sample Sinatra app with DataMapper
# Based on http://sinatra-book.gittr.com/ DataMapper example
require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/reloader' if development?
Bundler.require

require_relative 'model/post'
require_relative 'model/comment'

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


DataMapper.finalize
Post.auto_upgrade!
Comment.auto_upgrade!



class BlogExampleSinatra < Sinatra::Base

  # 404 Error!
  not_found do
    status 404
    erb :error_404
  end

  get '/' do
    @posts = Post.all(:order => [:id.desc], :limit => 20)
    erb :index
  end

  get '/post/new' do
    erb :new
  end

  get '/post/:id' do
    @post = Post.get(params[:id])
    erb @post ? :post : :error_404
  end

  post '/post/create' do
    post = Post.new(:title => params[:title], :body => params[:body])

    redirect '/post/new' unless post.title.length > 0 or post.body.length > 0

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

  post '/post/delete' do
    @post = Post.get(params[:id])
    @post.comments.destroy
    @post.destroy
    redirect '/'
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

end