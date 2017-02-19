require "jira_cache/version"
require "jira_cache/sync"
require "jira_cache/webhook_app"

# JiraCache enables storing JIRA issues fetched from the API
# in a local storage for easier and faster processing.
#
# This is the main module and it provides some high level
# methods to either trigger a full project sync, a single
# issue sync or start a Sinatra webhook app to trigger sync
# on JIRA"s webhooks.
module JiraCache

  # Sync issues using the specified client. If a `project_key` is
  # specified, only syncs the issues for the corresponding project.
  def self.sync_issues(client: default_client, project_key: nil)
    Sync.new(client).sync_issues(project_key: project_key)
  end

  def self.sync_issue(issue_key, client: default_client)
    Sync.new(client).sync_issue(issue_key)
  end

  # @param client [JiraCache::Client]: defaults to a default
  #   client using environment variables for domain, username
  #   and password, a logger writing to STDOUT and a default
  #   `JiraCache::Notifier` instance as notifier.
  def self.webhook_app(client: default_client)
    Sinatra.new(JiraCache::WebhookApp) do
      set(:client, client)
    end
  end

  def self.default_client
    JiraCache::Client.new(
      domain: ENV["JIRA_DOMAIN"],
      username: ENV["JIRA_USERNAME"],
      password: ENV["JIRA_PASSWORD"],
      logger: default_logger,
      notifier: default_notifier
    )
  end

  def self.default_logger
    logger = Logger.new(STDOUT)
    logger.level = Logger::DEBUG
    logger
  end

  def self.default_notifier(logger: default_logger)
    JiraCache::Notifier.new(logger)
  end
end
