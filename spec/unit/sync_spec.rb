# frozen_string_literal: true
require "spec_helper"
require "timecop"
require "jira_cache/sync"

describe JiraCache::Sync do

  subject { described_class.new(client) }
  let(:client) { double("JiraCache::Client", issue_data: {}, logger: nil) }
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

  describe "::sync_issues(project_key: nil)" do

    before do
      expect(subject)
        .to receive(:remote_keys)
        .with(project_key: project_key)
        .and_return(remote_keys)
      expect(subject)
        .to receive(:cached_keys)
        .with(project_key: project_key)
        .and_return(cached_keys)
      expect(subject)
        .to receive(:updated_keys)
        .with(project_key: project_key)
        .and_return(updated_keys)
    end

    it "fetches new and updated issues" do
      expect(subject).to receive(:fetch_issues).with(%w(a b c), now)
      subject.sync_issues(project_key: project_key)
    end

    it "marks deleted issues" do
      expect(subject).to receive(:mark_deleted).with(%w(e f))
      subject.sync_issues(project_key: project_key)
    end

    it "stores issues with the sync time" do
      subject.sync_issues(project_key: project_key)
      expect(JiraCache::Data::IssueRepository.latest_sync_time).to be_within(1).of latest_sync_time
    end
  end

  describe "::remote_keys(project_key: nil)" do
    it "fetches the issue keys for the project" do
      expect(subject).to receive(:fetch_issue_keys).with(project_key: project_key)
      subject.remote_keys(project_key: project_key)
    end
  end

  describe "::cached_keys(project_key: nil)" do
    it "fetches keys from cached issues" do
      expect(JiraCache::Data::IssueRepository)
        .to receive(:keys_in_project)
        .with(project_key: project_key)
      subject.cached_keys(project_key: project_key)
    end
  end

  describe "::updated_keys(project_key: nil)" do
    it "fetch issue keys for the project updated from the last sync date" do
      expect(subject).to receive(:latest_sync_time).and_return(latest_sync_time)
      expect(subject).to receive(:fetch_issue_keys).with(project_key: project_key, updated_since: latest_sync_time)
      subject.updated_keys(project_key: project_key)
    end
  end

  describe "::fetch_issue_keys(project_key: nil, updated_since: nil)" do

    context "with no parameter" do
      it "fetches issue keys with an empty JQL query" do
        expect(client)
          .to receive(:issue_keys_for_query)
          .with("")
        subject.fetch_issue_keys()
      end
    end

    context "with only the `project_key` parameter" do
      it "fetches issue keys with the project JQL query" do
        expect(client)
          .to receive(:issue_keys_for_query)
          .with("project = \"#{project_key}\"")
        subject.fetch_issue_keys(project_key: project_key)
      end
    end

    context "with both parameters" do
      it "fetches issue keys with the project and updated_since JQL query" do
        expected_jql = "project = \"#{project_key}\""
        expected_jql += " AND updatedDate > \"#{latest_sync_time.strftime('%Y-%m-%d %H:%M')}\""
        expect(client)
          .to receive(:issue_keys_for_query)
          .with(expected_jql)
        subject.fetch_issue_keys(project_key: project_key, updated_since: latest_sync_time)
      end
    end
  end
end
