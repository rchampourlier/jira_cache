ENV['RACK_ENV'] ||= ENV['APP_ENV'] ||= 'development'

root_dir = File.dirname(__FILE__)
require File.join(root_dir, 'config', 'boot')
require File.join(root_dir, 'lib', 'jira_cache', 'webhook_app')

logger = Logger.new(STDOUT)
logger.level = Logger::DEBUG
client = JiraCache::Client.new(
  domain: ENV['JIRA_CACHE_JIRA_DOMAIN'],
  username: ENV['JIRA_CACHE_JIRA_USERNAME'],
  password: ENV['JIRA_CACHE_JIRA_PASSWORD'],
  logger: logger,
  notifier: JiraCache::Notifier.new(logger)
)
run JiraCache.webhook_app(client)
