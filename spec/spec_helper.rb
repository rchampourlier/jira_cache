# Load dependencies
require 'rubygems'
require 'bundler/setup'

# Setup Coveralls
require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path('../..', __FILE__)
require 'config/boot'

require 'lib/jira_cache'

# Cleaning database after each test
require 'lib/jira_cache/issue'
require 'lib/jira_cache/state'
RSpec.configure do |config|
  config.after(:each) do
    JiraCache::Issue.destroy_all
    JiraCache::State.destroy_all
  end
end
