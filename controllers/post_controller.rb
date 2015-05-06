class PostController < ApplicationController
  set :views, File.expand_path('../../views/post', __FILE__)

  get '/' do
    redirect '/post/list'
  end

  get '/list' do
    @posts = Post.all(:order => [:id.desc], :limit => 20)
    erb :index
  end

  get '/create' do
    erb :create
  end

  post '/save' do
    post = Post.new(:title => params[:title], :body => params[:body])

    redirect '/post/create' unless post.title.length > 0 or post.body.length > 0

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

  get '/:id' do
    @post = Post.get(params[:id])
    erb @post ? :show : :error_404
  end

  get '/download-attachment/:id' do |post_id|
    file_name = Post.get(post_id).attachment
    send_file File.open('uploads/attachments/' + file_name)
    #redirect "/post/#{post.id}/#{file_name}"
  end

  get '/:id/edit' do |post_id|
    @post = Post.get(post_id)
    erb :edit
  end

  post '/update' do
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
      redirect "/post/#{post.id}/edit"
    end
  end

  post '/delete' do
    @post = Post.get(params[:id])
    @post.comments.destroy
    @post.destroy
    redirect '/'
  end

  post '/:id/comments/create' do |post_id|
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

  get '/:post_id/comments/delete/:comment_id' do |post_id, comment_id|
    comment = Comment.get(comment_id)
    comment.destroy
    redirect "/post/#{post_id}"
  end

end