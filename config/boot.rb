# frozen_string_literal: true
env = ENV["APP_ENV"] || "development"
if env == "development" || env == "test"
  require "dotenv"
  Dotenv.load(".env.#{env}")
end

root_dir = File.expand_path("../..", __FILE__)
$LOAD_PATH.unshift root_dir
$LOAD_PATH.unshift File.join(root_dir, "lib")
require "jira_cache"
