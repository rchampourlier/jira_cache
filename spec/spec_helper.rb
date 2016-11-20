# frozen_string_literal: true
# Load dependencies
require "rubygems"
require "bundler/setup"
require "rspec"
require "webmock/rspec"
require "rack/test"
require "pry"

require "simplecov"
SimpleCov.start do
  add_filter do |src|
    # Ignoring files from the spec directory
    src.filename =~ %r{/spec/}
  end
end

# ENV["APP_ENV"] replaces "RACK_ENV" since we're not in
# a Rack context.
ENV["APP_ENV"] = "test"
require File.expand_path("../../config/boot", __FILE__)

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require(f) }

# Database setup, teardown and cleanup during tests
require "sequel/extensions/migration"
require "jira_cache/data"
require "jira_cache/data/issue_repository"
client = JiraCache::Data::DB

MIGRATIONS_DIR = File.expand_path("../../config/db_migrations", __FILE__)
RSpec.configure do |config|

  config.before(:all) do
    Sequel::Migrator.apply(client, MIGRATIONS_DIR)
  end

  config.after(:each) do
    JiraCache::Data::IssueRepository.delete_where("TRUE")
  end

  config.after(:all) do
    Sequel::Migrator.apply(client, MIGRATIONS_DIR, 0)
  end
end

require "jira_cache"
