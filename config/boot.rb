env = ENV['JIRA_CACHE_ENV'] || 'development'
if env == 'development' || env == 'test'
  require 'dotenv'
  Dotenv.load
end

root_dir = File.expand_path('../..', __FILE__)
$LOAD_PATH.unshift root_dir
$LOAD_PATH.unshift File.join(root_dir, 'lib')
require 'config/mongo'
require 'jira_cache'
