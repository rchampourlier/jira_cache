# frozen_string_literal: true
require "spec_helper"
require "timecop"

describe JiraCache::Sync do

  let(:client) { double("JiraCache::Client", issue_data: {}) }
  let(:now) { Time.now }

  before do
    Timecop.freeze(now)
  end

  after { Timecop.return }

  it "has a version number" do
    expect(JiraCache::VERSION).not_to be nil
  end

  let(:project_key) { "project_key" }
  let(:remote_keys) { %w(a b c d) }
  let(:cached_keys) { %w(c d e f) }
  let(:updated_keys) { %w(c) }
  let(:latest_sync_time) { now }

  describe "::sync_project_issues(client, project_key)" do

    before do
      expect(described_class)
        .to receive(:remote_keys)
        .with(client, project_key)
        .and_return(remote_keys)
      expect(described_class)
        .to receive(:cached_keys)
        .with(project_key)
        .and_return(cached_keys)
      expect(described_class)
        .to receive(:updated_keys)
        .with(client, project_key)
        .and_return(updated_keys)
    end

    it "fetches new and updated issues" do
      expect(described_class).to receive(:fetch_issues).with(client, %w(a b c), now)
      described_class.sync_project_issues(client, project_key)
    end

    it "marks deleted issues" do
      expect(described_class).to receive(:mark_deleted).with(%w(e f))
      described_class.sync_project_issues(client, project_key)
    end

    it "stores issues with the sync time" do
      described_class.sync_project_issues(client, project_key)
      expect(JiraCache::Data::IssueRepository.latest_sync_time).to be_within(1).of latest_sync_time
    end
  end

  describe "::remote_keys(client, project_key)" do
    it "fetches the issue keys for the project" do
      expect(described_class).to receive(:fetch_issue_keys).with(client, project_key)
      described_class.remote_keys(client, project_key)
    end
  end

  describe "::cached_keys(project_key)" do
    it "fetches keys from cached issues" do
      expect(JiraCache::Data::IssueRepository)
        .to receive(:keys_in_project)
        .with(project_key)
      described_class.cached_keys(project_key)
    end
  end

  describe "::updated_keys(project_key)" do
    it "fetch issue keys for the project updated from the last sync date" do
      expect(described_class).to receive(:latest_sync_time).and_return(latest_sync_time)
      expect(described_class).to receive(:fetch_issue_keys).with(client, project_key, updated_since: latest_sync_time)
      described_class.updated_keys(client, project_key)
    end
  end

  describe "::fetch_issue_keys(client, project_key[, updated_since])" do

    context "without updated_since parameter" do
      it "fetches issue keys with the project JQL query" do
        expect(client)
          .to receive(:issue_keys_for_query)
          .with("project = \"#{project_key}\"")
        described_class.fetch_issue_keys(client, project_key)
      end
    end

    context "with updated_since parameter" do
      it "fetches issue keys with the project and updated_since JQL query" do
        expected_jql = "project = \"#{project_key}\""
        expected_jql += " AND updatedDate > \"#{latest_sync_time.strftime('%Y-%m-%d %H:%M')}\""
        expect(client)
          .to receive(:issue_keys_for_query)
          .with(expected_jql)
        described_class.fetch_issue_keys(client, project_key, updated_since: latest_sync_time)
      end
    end
  end
end
