require "spec_helper"
require "jira_cache/webhook_app"
require "json"

describe JiraCache::WebhookApp do
  include Rack::Test::Methods

  def client_info
    { "domain" => "test_domain", "username" => "test_user" }
  end

  def client
    @client ||= double("JiraCache::Client", info: client_info, logger: nil)
  end

  def app
    the_client = client
    Sinatra.new(described_class) do
      set :client, the_client
    end
  end

  let(:sync_double) { double("Sync") }
  before do
    allow(JiraCache::Sync).to receive(:new).and_return(sync_double)
  end

  describe "GET /" do
    let(:response) { get "/"; last_response }

    it "responds a successful response" do
      expect(response.status).to eq(200)
    end

    it "responds with the application name" do
      expect(JSON.parse(response.body)["app"]).to eq("jira_cache/webhook_app")
    end

    it "responds with a status" do
      expect(JSON.parse(response.body)["status"]).to eq("ok")
    end

    it "responds with the client info" do
      expect(JSON.parse(response.body)["client"]).to eq(client_info)
    end
  end

  describe "POST /" do

    let(:payload) do
      {
        "webhookEvent": event,
        "issue": issue
      }
    end
    let(:issue) do
      {
        "key" => issue_key
      }
    end
    let(:issue_key) { "issue_key" }

    context "issue created" do
      let(:event) { "jira:issue_created" }

      it "syncs the created issue" do
        expect(sync_double)
          .to receive(:sync_issue)
          .with(issue_key)
        post "/", payload.to_json, "CONTENT-TYPE" => "application/json"
      end
    end

    context "issue updated" do
      let(:event) { "jira:issue_updated" }

      it "syncs the updated issue" do
        expect(sync_double)
          .to receive(:sync_issue)
          .with(issue_key)
        post "/", payload.to_json, "CONTENT-TYPE" => "application/json"
      end
    end

    context "issue deleted" do
      let(:event) { "jira:issue_deleted" }

      it "marks the issues as deleted" do
        expect(sync_double)
          .to receive(:mark_deleted)
          .with([issue_key])
        post "/", payload.to_json, "CONTENT-TYPE" => "application/json"
      end
    end
  end
end
