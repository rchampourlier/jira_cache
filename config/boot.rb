# Load dependencies
require 'rubygems'
require 'bundler/setup'
env = ENV['JIRA_CACHE_ENV'] || 'development'
if env == 'development'
  require 'dotenv'
  Dotenv.load
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'config/mongo'
require 'jira_cache'
