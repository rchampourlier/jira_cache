require 'mongoid'

env = ENV['JIRA_CACHE_ENV']
raise 'JIRA_CACHE_ENV environment variable must be set' if env.nil?

ENV['MONGOID_ENV'] = env

Mongoid.load! File.expand_path('../mongoid.yml', __FILE__)
