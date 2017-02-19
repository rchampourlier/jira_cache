ENV["RACK_ENV"] ||= ENV["APP_ENV"] ||= "development"

root_dir = File.dirname(__FILE__)
require File.join(root_dir, "config", "boot")
require File.join(root_dir, "lib", "jira_cache", "webhook_app")

run JiraCache.webhook_app
