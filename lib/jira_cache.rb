require 'thread/pool'
require 'jira_cache/version'
require 'jira_cache/sync'
require 'jira_cache/webhook_app'

# Facility to store/cache JIRA issues data in a MongoDB datastore.
module JiraCache

  def sync_project_issues(client, project_key)
    Sync.sync_project_issues(client, project_key)
  end
  module_function :sync_project_issues

  def sync_issue(client, issue_key)
    Sync.sync_issue(client, issue_key)
  end
  module_function :sync_issue

  # @param client [JiraCache::Client]
  def webhook_app(client)
    Sinatra.new(JiraCache::WebhookApp) do
      set(:client, client)
    end
  end
  module_function :webhook_app
end
