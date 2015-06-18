require 'spec_helper'

describe JiraCache::State do
  let(:project_key) { 'project_key' }
  let(:sync_time) { Time.now }

  describe '::project_sync_time(project_key)' do
    subject { described_class.project_sync_time(project_key) }

    context 'no state saved' do
      it { should be_nil }
    end

    context 'state saved' do
      before { described_class.create(project_key: project_key, sync_time: sync_time) }
      it 'should return the sync time (with precision < 0.001 - MongoDB limitation)' do
        expect(subject - sync_time).to be < 0.001
      end
    end
  end

  describe '::synced_project!(project_key, time)' do
    it 'should create a state for the project and specified sync time (with precision < 0.001)' do
      described_class.synced_project!(project_key, sync_time)
      expect(described_class.count).to eq(1)
      expect(described_class.first.project_key).to eq(project_key)
      expect(described_class.first.sync_time - sync_time).to be < 0.001
    end
  end
end
