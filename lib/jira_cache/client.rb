require 'httparty'
require 'cgi'

module JiraCache
  class Client
    include HTTParty
    base_uri 'https://jobteaser.atlassian.net/rest/api/2'

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
      content = do_get("/issue/#{id_or_key}", options.merge(
        query: {
          expand: EXPANDED_FIELDS.join(',')
        }
      )).to_hash
      if incomplete_worklogs?(content)
        content['fields']['worklog'] = issue_worklog_content(id_or_key)
      end
      content
    end

    def self.incomplete_worklogs?(issue_data)
      worklog = issue_data['fields']['worklog']
      worklog['total'].to_i > worklog['maxResults'].to_i
    end

    def self.issue_worklog_content(id_or_key)
      do_get("/issue/#{id_or_key}/worklog", options).to_hash
    end

    def self.issue_keys_for_query(jql_query)
      start_at = 0
      issues = []
      begin
        results = issue_ids_in_limits jql_query, start_at
        total_issues_count = results['total']
        logger.info "Total number of issues: #{total_issues_count}" if issues.length == 0
        request_issues = results['issues']
        issues += request_issues
        logger.info "  -- loaded #{issues.length} issues"
        start_at += request_issues.length
      end while issues.length < total_issues_count
      issues.collect {|issue| issue['key']}
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

    def self.issue_ids_in_limits(jql_query, start_at)
      do_get '/search', options.merge({
        query: {
          jql: jql_query,
          startAt: start_at,
          fields: 'id',
          maxResults: JIRA_MAX_RESULTS
        }
      })
    end

    def self.options
      {
        basic_auth: {
          username: @username,
          password: @password
        },
        headers: {
          'Content-Type' => 'application/json'
        }
      }
    end

    def self.config=(username: nil, password: nil, log_level: Logger::FATAL)
      @username = username
      raise 'Missing username' if username.blank?
      @password = password
      raise 'Missing password' if password.blank?
      @log_level = log_level
    end

    def self.logger
      @logger ||= (
        logger = ::Logger.new(STDOUT)
        logger.level = @log_level
        logger
      )
    end
  end
end
