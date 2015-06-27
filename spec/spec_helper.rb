# Load dependencies
require 'rubygems'
require 'bundler/setup'

if ENV['CI']
  # Running on CI, setup Coveralls
  require 'coveralls'
  Coveralls.wear!
else
  # Running locally, setup simplecov
  require 'simplecov'
  require 'simplecov-json'
  SimpleCov.start
  SimpleCov.formatter = SimpleCov::Formatter::JSONFormatter
end

$LOAD_PATH.unshift File.expand_path('../..', __FILE__)
require 'config/boot'

require 'lib/jira_cache'

# Cleaning database after each test
require 'lib/jira_cache/issue'
require 'lib/jira_cache/project_state'
RSpec.configure do |config|
  config.after(:each) do
    JiraCache::Issue.destroy_all
    JiraCache::ProjectState.destroy_all
  end
end
