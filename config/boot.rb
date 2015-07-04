env = ENV['JIRA_CACHE_ENV'] || 'development'
if env == 'development' || env == 'test'
  require 'dotenv'
  Dotenv.load
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'config/mongo'
require 'jira_cache'
