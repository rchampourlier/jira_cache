require 'spec_helper'
require 'jira_cache/notifier'

describe JiraCache::Notifier do

  describe '::published(name, data = nil)' do
    let(:event_name) { 'test' }
    let(:data) { { data: 1 } }

    it 'logs the event name and data' do
      logger = ::Logger.new('/dev/null')
      notifier = described_class.new(logger)
      expect(logger).to receive(:info).with("[test] #{data}")
      notifier.publish event_name, data
    end
  end
end
