require 'spec_helper'

describe JiraCache do

  it 'has a version number' do
    expect(JiraCache::VERSION).not_to be nil
  end

  let(:project_key) { 'project_key' }

  describe '::sync_issues(project_key)' do
    let(:remote_keys) { %w(a b c d) }
    let(:cached_keys) { %w(c d e f) }

    it 'should fetch each issue whose key is not in the cached issue keys' do
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
        .and_return([])

      expect(described_class).to receive(:fetch_issues).with(%w(a b)).once.ordered
      expect(described_class).to receive(:fetch_issues)
      expect(described_class).to receive(:mark_deleted)

      described_class.sync_issues(project_key)
    end

    it 'should fetch each issue which has been updated since the last sync'

    it 'should mark as deleted each issue present in cache and not in JIRA'

    context 'successful sync' do
      it 'should update the last sync time'
    end

    context 'failed sync' do
      it 'should not update the last sync time'
    end
  end
end
