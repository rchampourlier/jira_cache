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

  def sync_project_issues(client, project_key)
    Sync.new(client).sync_project_issues(project_key)
  end
  module_function :sync_project_issues

  def sync_issue(client, issue_key)
    Sync.new(client).sync_issue(issue_key)
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
