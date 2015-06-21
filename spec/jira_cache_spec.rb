require 'spec_helper'

describe JiraCache do

  before do
    # Stubbing out some methods which we can ignore in the context
    # of these specs.
    JiraCache::Client.stub(issue_data: {})
    JiraCache::Issue.stub(deleted_from_jira!: true)
  end

  it 'has a version number' do
    expect(JiraCache::VERSION).not_to be nil
  end

  let(:project_key) { 'project_key' }

  describe '::sync_issues(project_key)' do
    let(:remote_keys) { %w(a b c d) }
    let(:cached_keys) { %w(c d e f) }
    let(:updated_keys) { %w(c) }

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

    it 'should fetch new and updated issues' do
      expect(described_class).to receive(:fetch_issues).with(%w(a b c))
      # expect(described_class).to receive(:mark_deleted)
      described_class.sync_issues(project_key)
    end

    it 'should mark deleted issues' do
      expect(described_class).to receive(:mark_deleted).with(%w(e f))
      described_class.sync_issues(project_key)
    end

    it 'should update the last sync time' do
      expect(described_class.last_sync_time(project_key)).to be_nil
      described_class.sync_issues(project_key)
      time = described_class.last_sync_time(project_key)
      expect(time).not_to be_nil
      expect(time).to be >= Time.now - 10.seconds
    end
  end
end
