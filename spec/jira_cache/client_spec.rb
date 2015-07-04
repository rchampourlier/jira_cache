require 'spec_helper'
require 'jira_cache/client'
require 'support/response_fixture'
require 'webmock/rspec'

describe JiraCache::Client do
  let(:domain) { 'example.com' }
  let(:username) { 'username' }
  let(:password) { 'password' }

  before do
    described_class.set_config(domain: domain, username: username, password: password)
  end

  describe '::issue_data(id_or_key)' do
    let(:response) { ResponseFixture.get("get_issue_#{issue_key}")}
    let(:headers) { { 'Content-Type' => 'application/json' } }
    let(:url) { "https://#{username}:#{password}@#{domain}/rest/api/2/issue/#{issue_key}" }
    let(:url_query) { '?expand=renderedFields,changelog' }
    before do
      stub_request(:get, "#{url}#{url_query}")
        .with(headers: headers)
        .to_return(status: 200, body: response, headers: headers)
    end

    context 'issue not found' do
      let(:issue_key) { 'not_found' }

      it 'returns nil' do
        result = described_class.issue_data(issue_key)
        expect(result).to be_nil
      end
    end

    context 'simple issue' do
      let(:issue_key) { 'simple' }
      let(:notifier) { double('Notifier', publish: nil) }
      before { described_class.set_notifier(notifier) }
      after { described_class.set_notifier(nil) }
      let(:issue_data) { JSON.parse(response) }

      it 'fetches the issue data' do
        result = described_class.issue_data(issue_key)
        expect(result.keys).to include('fields')
      end

      it 'publish an event through the notifier' do
        expect(notifier).to receive(:publish).with('jira_cache:fetched_issue', key: issue_key, data: issue_data)
        described_class.issue_data(issue_key)
      end
    end

    context 'issue with lots of worklog' do
      let(:issue_key) { 'many_worklogs' }

      it 'fetches all worklogs' do
        worklog_response = ResponseFixture.get("get_issue_worklog_#{issue_key}")
        stub_request(:get, "#{url}/worklog")
          .with(headers: headers)
          .to_return(status: 200, body: worklog_response, headers: headers)

        result = described_class.issue_data(issue_key)
        expect(result['fields']['worklog']['worklogs'].count).to eq(3)
      end
    end
  end

  describe '::issue_keys_for_query(jql_query)' do

    context 'single request query' do
      let(:jql_query) { 'project="single_request"' }
      # let(:jql_query) { 'project="JT"' }

      it 'returns ids from the query results' do
        url = "https://#{username}:#{password}@#{domain}/rest/api/2/search"
        url_query = "?fields=id&jql=#{jql_query}&maxResults=1000&startAt=0"
        headers = { 'Content-Type' => 'application/json' }
        response = ResponseFixture.get('get_issue_keys_jql_query_project="single_request"_start_at_0')

        stub_request(:get, "#{url}#{url_query}")
          .with(headers: headers)
          .to_return(status: 200, body: response, headers: headers)

        result = described_class.issue_keys_for_query(jql_query)
        expect(result.count).to eq(2)
      end
    end

    context 'query spanning over multiple requests' do
      let(:jql_query) { 'project="multiple_requests"' }

      it 'returns ids from the multiple requests' do
        url = "https://#{username}:#{password}@#{domain}/rest/api/2/search"
        url_query_1 = "?fields=id&jql=#{jql_query}&maxResults=1000&startAt=0"
        url_query_2 = "?fields=id&jql=#{jql_query}&maxResults=1000&startAt=5"
        url_query_3 = "?fields=id&jql=#{jql_query}&maxResults=1000&startAt=10"
        headers = { 'Content-Type' => 'application/json' }

        response_fixture_prefix = 'get_issue_keys_jql_query_project="multiple_requests"_start_at_'
        response_1 = ResponseFixture.get("#{response_fixture_prefix}0")
        response_2 = ResponseFixture.get("#{response_fixture_prefix}5")
        response_3 = ResponseFixture.get("#{response_fixture_prefix}10")

        stub_request(:get, "#{url}#{url_query_1}")
          .with(headers: headers)
          .to_return(status: 200, body: response_1, headers: headers)
        stub_request(:get, "#{url}#{url_query_2}")
          .with(headers: headers)
          .to_return(status: 200, body: response_2, headers: headers)
        stub_request(:get, "#{url}#{url_query_3}")
          .with(headers: headers)
          .to_return(status: 200, body: response_3, headers: headers)

        result = described_class.issue_keys_for_query(jql_query)
        expect(result.count).to eq(11)
      end
    end
  end
end
