###########
# config.ru
#
$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/reloader' if development?
Bundler.require

Dir.glob('./{models,helpers,controllers}/*.rb').each { |file| require file }

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

DataMapper.finalize
Post.auto_upgrade!
Comment.auto_upgrade!

map('/')     { run ApplicationController }
map('/post') { run PostController }