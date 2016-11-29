# frozen_string_literal: true
require "sinatra/base"
require "json"
require "jira_cache/sync"

module JiraCache

  # A Sinatra::Base application to process JIRA webhooks.
  #
  # Defines 2 routes:
  #   - GET /: provides a basic JSON status,
  #   - POST /: which processes a webhook.
  class WebhookApp < Sinatra::Base

    # GET /
    # Returns JSON with the app name and a status
    get "/" do
      default_response
    end

    # POST /
    # Endpoint for JIRA webhook
    post "/" do
      client = self.class.client
      request.body.rewind # in case it was already read
      data = JSON.parse(request.body.read)
      issue_key = data["issue"]["key"]

      case (webhook_event = data["webhookEvent"])
      when "jira:issue_created", "jira:issue_updated", "jira:worklog_updated"
        JiraCache::Sync.new(client).sync_issue(issue_key)
      when "jira:issue_deleted"
        JiraCache::Sync.new.mark_deleted([issue_key])
      else
        raise "Unknown webhook event \"#{webhook_event}\""
      end

      default_response
    end

    # Returns the client (`JiraCache::Client`) defined on
    # the class (see `JiraCache.webhook_app(...)`).
    def client
      self.class.client
    end

    def default_response
      {
        app: "jira_cache/webhook_app",
        status: "ok",
        client: client.info
      }.to_json
    end
  end
end
