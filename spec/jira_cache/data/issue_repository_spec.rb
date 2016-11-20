# frozen_string_literal: true
require "spec_helper"
require "timecop"
require "jira_cache/data/issue_repository"

describe JiraCache::Data::IssueRepository do
  let(:time) { Time.now }
  let(:issue1_data) { { "key" => "key1", "project" => "PJ1", "value" => "value1" } }
  let(:issue2_data) { { "key" => "key2", "project" => "PJ2", "value" => "value2" } }
  let(:issue3_data) { { "key" => "key3", "project" => "PJ1", "value" => "value3" } }

  before do
    Timecop.freeze(time)
    described_class.insert(key: "key1", data: issue1_data, synced_at: time)
    described_class.insert(key: "key2", data: issue2_data, synced_at: time)
    described_class.insert(key: "key3", data: issue3_data, synced_at: time)
  end
  after { Timecop.return }

  describe "::find_by_key(issue_key)" do

    context "matching issue exists" do
      it "returns the issue's attributes" do
        result = described_class.find_by_key("key1")
        expect(result[:data]["value"]).to eq("value1")
      end
    end

    context "no matching issue" do
      it "returns nil" do
        expect(described_class.find_by_key("unknown")).to eq(nil)
      end
    end
  end

  describe "::insert(key:, data:, synced_at:, deleted_from_jira_at: nil)" do
    context "successful" do
      let(:key) { SecureRandom.uuid }
      subject do
        described_class.insert(key: key, data: issue1_data, synced_at: time)
      end

      it "returns nil" do
        expect(subject).to eq(nil)
      end

      it "created the row" do
        subject
        expect(JiraCache::Data::IssueRepository.find_by_key(key)).not_to be_nil
      end
    end
  end

  describe "::keys_in_project(project_key)" do
    subject { described_class.keys_in_project("PJ1") }
    it { should eq(%w(key1 key3)) }
  end
end
