require 'spec_helper'
require 'jira_cache/notifier'

describe JiraCache::Notifier do

  describe '::published(name, data = nil)' do
    let(:event_name) { 'test' }
    let(:issue_data) { { 'value' => 'issue_value', 'key' => 'issue_data_key' } }
    let(:event_data) { { key: 'issue_key', data: issue_data } }

    it 'logs the event name and event\'s data key' do
      logger = ::Logger.new('/dev/null')
      notifier = described_class.new(logger)
      expect(logger).to receive(:info).with("[test] #{event_data[:key]}")
      notifier.publish event_name, event_data
    end
  end
end
