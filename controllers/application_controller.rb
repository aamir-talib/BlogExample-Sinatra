# Sample Sinatra app with DataMapper
# Based on http://sinatra-book.gittr.com/ DataMapper example
require 'sinatra/base'

class ApplicationController < Sinatra::Base
  helpers ApplicationHelpers

  set :views, File.expand_path('../../views', __FILE__)
  get '/' do
    redirect to('/post')
    #@posts = Post.all(:order => [:id.desc], :limit => 20)
    #erb :index
  end

end