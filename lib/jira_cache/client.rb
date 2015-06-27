require 'httparty'
require 'cgi'

module JiraCache

  # The JIRA API Client.
  class Client
    include HTTParty

    JIRA_MAX_RESULTS = 1000
    EXPANDED_FIELDS = %w(
      renderedFields
      changelog
    )
    # Other fields: names, schema, operations, editmeta

    # Fetches the issue represented by id_or_key from the
    # client.
    # If the data is already present in the cache,
    # returns the cached version, unless if :allow_cache
    # option is false.
    def self.issue_data(id_or_key)
      logger.info "Fetching data for issue #{id_or_key}"
      issue_data = do_get("/issue/#{id_or_key}", options.merge(
        query: {
          expand: EXPANDED_FIELDS.join(',')
        }
      )).to_hash
      return nil if issue_not_found?(issue_data)
      complete_worklogs(id_or_key, issue_data)
    end

    def self.issue_keys_for_query(jql_query)
      start_at = 0
      issues = []
      loop do
        total, page_issues = issue_ids_in_limits(jql_query, start_at)
        logger.info "Total number of issues: #{total}" if issues.length == 0
        issues += page_issues
        logger.info "  -- loaded #{page_issues.length} issues"
        start_at = page_issues.length
        break if issues.length == total
      end
      issues.collect { |issue| issue['key'] }
    end

    # Implementation methods
    # ======================

    def self.issue_not_found?(issue_data)
      return false if issue_data['errorMessages'].nil?
      issue_data['errorMessages'].first == 'Issue Does Not Exist'
    end

    def self.complete_worklogs(id_or_key, issue_data)
      if incomplete_worklogs?(issue_data)
        issue_data['fields']['worklog'] = issue_worklog_content(id_or_key)
      end
      issue_data
    end

    def self.incomplete_worklogs?(issue_data)
      worklog = issue_data['fields']['worklog']
      worklog['total'].to_i > worklog['maxResults'].to_i
    end

    def self.issue_worklog_content(id_or_key)
      do_get("/issue/#{id_or_key}/worklog", options).to_hash
    end

    def self.project_data(id)
      do_get "/project/#{id}", options
    end

    def self.projects_data
      do_get '/project', options
    end

    def self.do_get(path, options)
      logger.debug "GET #{path} #{options}"
      get path, options
    end

    # @return [total, issues]
    #   - total: [Int] the total number of issues in the query results
    #   - issues: [Array] array of issues in the response
    #     (max `JIRA_MAX_RESULTS`)
    def self.issue_ids_in_limits(jql_query, start_at)
      results = do_get '/search', options.merge(
        query: {
          jql: jql_query,
          startAt: start_at,
          fields: 'id',
          maxResults: JIRA_MAX_RESULTS
        }
      )
      [results['total'], results['issues']]
    end

    def self.options
      options = {
        headers: {
          'Content-Type' => 'application/json'
        },
        verify: false
      }
      return options if @username.blank?
      options.merge({
        basic_auth: {
          username: @username,
          password: @password
        }
      })
    end

    def self.set_config(domain, username = nil, password = nil, log_level: ::Logger::FATAL)
      fail 'Missing domain' if domain.blank?
      base_uri "https://#{domain}/rest/api/2"
      @username = username
      @password = password
      @log_level = log_level
    end

    def self.logger
      @logger ||= (
        logger = ::Logger.new(STDOUT)
        logger.level = @log_level || ::Logger::FATAL
        logger
      )
    end
  end
end
