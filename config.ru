###########
# config.ru
#

require File.dirname(__FILE__) + '/sinatra_dm'

configure do
  set :erb, :layout => :'views/layouts/layout.erb'
end

run BlogExampleSinatra