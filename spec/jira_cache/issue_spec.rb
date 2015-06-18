require 'spec_helper'

describe JiraCache::Issue do

  let(:data1) { { 'key' => 'key1', 'value' => 'value1' } }
  let(:data2) { { 'key' => 'key2', 'value' => 'value2' } }

  describe '::find_by_key(issue_key)' do
    let!(:doc1) { described_class.create(key: 'key1', data: data1) }
    let!(:doc2) { described_class.create(key: 'key2', data: data2) }
    subject { described_class.find_by_key('key1') }
    it { should eq(doc1) }
  end

  describe '::create_or_update(issue_data)' do
    subject { described_class.create_or_update(data1).key }
    it { should eq(data1['key']) }
  end

  describe '::deleted_from_jira!(issue_key)' do
    let(:key) { 'key' }
    let(:doc) { described_class.create(key: key, data: data1) }

    it 'should set "deleted_from_jira_at" to current time' do
      expect(doc.deleted_from_jira_at).to be_nil
      described_class.deleted_from_jira!(key)
      doc.reload
      expect(doc.deleted_from_jira_at > 1.minute.ago).to be true
    end
  end

  describe '::keys' do
    let!(:doc1) { described_class.create(key: 'key1', data: data1) }
    let!(:doc2) { described_class.create(key: 'key2', data: data2) }
    subject { described_class.keys }
    it { should eq(['key1', 'key2']) }
  end
end
