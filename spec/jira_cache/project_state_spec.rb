require 'spec_helper'

describe JiraCache::ProjectState do
  let(:project_key) { 'project_key' }
  let(:synced_at) { Time.now }

  describe '::sync_time(project_key)' do
    subject { described_class.sync_time(project_key) }

    context 'no project_state saved' do
      it { should be_nil }
    end

    context 'project_state saved' do
      before do
        described_class.create(project_key: project_key, synced_at: synced_at)
      end

      it 'should return the sync time (with precision < 0.001 - MongoDB limitation)' do
        expect(subject - synced_at).to be < 0.001
      end
    end
  end

  describe '::synced_project!(project_key, time)' do
    it 'should create a project_state for the project and specified sync time (with precision < 0.001)' do
      described_class.synced_project!(project_key, synced_at)
      expect(described_class.count).to eq(1)
      expect(described_class.first.project_key).to eq(project_key)
      expect(described_class.first.synced_at - synced_at).to be < 0.001
    end
  end
end
