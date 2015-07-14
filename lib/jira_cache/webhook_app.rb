require 'sinatra/base'
require 'json'
require 'jira_cache/sync'

module JiraCache
  class WebhookApp < Sinatra::Base

    # GET /
    # Returns JSON with the app name and a status
    get '/' do
      {
        app: 'jira_cache/webhook_app',
        status: 'ok',
        client: client.info
      }.to_json
    end

    # POST /
    # Endpoint for JIRA webhook
    post '/' do
      client = self.class.client
      request.body.rewind # in case it was already read
      data = JSON.parse(request.body.read)
      issue_key = data['issue']['key']

      case (webhook_event = data['webhookEvent'])
      when 'jira:issue_created', 'jira:issue_updated', 'jira:worklog_updated'
        JiraCache::Sync.sync_issue(client, issue_key)
      when 'jira:issue_deleted'
        JiraCache::Sync.mark_deleted([issue_key])
      else
        fail "Unknown webhook event \"#{webhook_event}\""
      end
    end

    # Returns the client (`JiraCache::Client`) defined on
    # the class (see `JiraCache.webhook_app(...)`).
    def client
      self.class.client
    end
  end
end
