require 'spec_helper'

describe JiraCache do

  before do
    # Stubbing out some methods which we can ignore in the context
    # of these specs.
    allow(JiraCache::Client).to receive(:issue_data).and_return({})
    allow(JiraCache::Issue).to receive(:deleted_from_jira!).and_return(true)
  end

  it 'has a version number' do
    expect(JiraCache::VERSION).not_to be nil
  end

  let(:project_key) { 'project_key' }
  let(:remote_keys) { %w(a b c d) }
  let(:cached_keys) { %w(c d e f) }
  let(:updated_keys) { %w(c) }
  let(:last_sync_time) { Time.now }

  describe '::sync_issues(project_key)' do

    before do
      expect(described_class)
        .to receive(:remote_keys)
        .with(project_key)
        .and_return(remote_keys)
      expect(described_class)
        .to receive(:cached_keys)
        .with(project_key)
        .and_return(cached_keys)
      expect(described_class)
        .to receive(:updated_keys)
        .with(project_key)
        .and_return(updated_keys)
    end

    it 'fetches new and updated issues' do
      expect(described_class).to receive(:fetch_issues).with(%w(a b c))
      # expect(described_class).to receive(:mark_deleted)
      described_class.sync_issues(project_key)
    end

    it 'marks deleted issues' do
      expect(described_class).to receive(:mark_deleted).with(%w(e f))
      described_class.sync_issues(project_key)
    end

    it 'updates the last sync time' do
      expect(described_class.last_sync_time(project_key)).to be_nil
      described_class.sync_issues(project_key)
      time = described_class.last_sync_time(project_key)
      expect(time).not_to be_nil
      expect(time).to be >= Time.now - 10.seconds
    end
  end

  describe '::remote_keys(project_key)' do
    it 'fetches the issue keys for the project' do
      expect(described_class).to receive(:fetch_issue_keys).with(project_key)
      described_class.remote_keys(project_key)
    end
  end

  describe '::cached_keys(project_key)' do
    it 'fetches keys from cached issues' do
      expect(JiraCache::Issue).to receive(:keys).with(project_key: project_key)
      described_class.cached_keys(project_key)
    end
  end

  describe '::missing_keys(remote_keys, cached_keys)' do
    it 'returns keys in remote keys and not in cached ones' do
      result = described_class.missing_keys remote_keys, cached_keys
      expect(result).to eq(%w(a b))
    end
  end

  describe '::updated_keys(project_key)' do
    it 'fetch issue keys for the project updated from the last sync date' do
      expect(described_class).to receive(:last_sync_time).and_return(last_sync_time)
      expect(described_class).to receive(:fetch_issue_keys).with(project_key, updated_since: last_sync_time)
      described_class.updated_keys(project_key)
    end
  end

  describe '::fetch_issue_keys(project_key[, updated_since])' do

    context 'without updated_since parameter' do
      it 'fetches issue keys with the project JQL query' do
        expect(JiraCache::Client)
          .to receive(:issue_keys_for_query)
          .with("project = \"#{project_key}\"")
        described_class.fetch_issue_keys(project_key)
      end
    end

    context 'with updated_since parameter' do
      it 'fetches issue keys with the project and updated_since JQL query' do
        expected_jql = "project = \"#{project_key}\""
        expected_jql << " AND updatedDate > \"#{last_sync_time.strftime('%Y-%m-%d %H:%M')}\""
        expect(JiraCache::Client)
          .to receive(:issue_keys_for_query)
          .with(expected_jql)
        described_class.fetch_issue_keys(project_key, updated_since: last_sync_time)
      end
    end
  end
end
