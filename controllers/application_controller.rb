# Sample Sinatra app with DataMapper
# Based on http://sinatra-book.gittr.com/ DataMapper example
require 'sinatra/base'

class ApplicationController < Sinatra::Base
  helpers ApplicationHelpers

  set :views, File.expand_path('../../views', __FILE__)
  set :erb, :layout => :'../layouts/default'
  set :public_folder, 'public'

  get '/' do
    redirect to('/post')
  end

end