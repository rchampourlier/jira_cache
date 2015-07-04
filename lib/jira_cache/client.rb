require 'httparty'
require 'cgi'
require 'jira_cache/notifier'

module JiraCache

  # The JIRA API Client.
  class Client
    include HTTParty

    JIRA_MAX_RESULTS = 1000

    EXPANDED_FIELDS = %w(
      renderedFields
      changelog
    )
    # Other possible fields: names, schema, operations, editmeta

    # Returns the config. If the config was not set using
    # #set_config, an exception is raised.
    def self.config
      fail 'Config not set. Please set config first (JiraCache::Client.config=...).' if @config.nil?
      @config
    end

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
      issue_data = complete_worklogs(id_or_key, issue_data)
      notifier.publish 'jira_cache:fetched_issue', key: id_or_key, data: issue_data
      issue_data
    end

    def self.issue_keys_for_query(jql_query)
      start_at = 0
      issues = []
      loop do
        total, page_issues = issue_ids_in_limits(jql_query, start_at)
        logger.info "Total number of issues: #{total}" if issues.length == 0
        issues += page_issues
        logger.info "  -- loaded #{page_issues.length} issues"
        start_at = issues.length
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
      return options if config[:username].blank?
      options.merge({
        basic_auth: {
          username: config[:username],
          password: config[:password]
        }
      })
    end

    # @param config [Hash] config hash, with the following key-values:
    #   - :domain => [String] domain of the JIRA API to be requested
    #   - :username => [String] JIRA username (optional, defaults to nil)
    #   - :password => [String] JIRA password for the specified user (optional, default to nil)
    #   - :log_level => [::Logger::LOG_LEVEL] (optional, defaults to Logger::FATAL)
    def self.set_config(domain:, username: nil, password: nil, log_level: ::Logger::FATAL)
      fail 'Missing domain' if domain.blank?
      base_uri "https://#{domain}/rest/api/2"
      @config = {
        domain: domain,
        username: username,
        password: password,
        log_level: log_level
      }
    end

    # @param notifier [Object] the passed object must implement the notifier contract
    #   (see `JiraCache::Notifier`).
    def self.set_notifier(notifier)
      @notifier = notifier
    end

    def self.logger
      @logger ||= (
        logger = ::Logger.new(STDOUT)
        logger.level = config[:log_level] || ::Logger::FATAL
        logger
      )
    end

    # Returns a notifier, which will be used to send some events
    # (currently only "jira_cache:fetched_issue").
    # For now, this method only returns an instance of JiraCache::Notifier,
    # which uses ActiveSupport::Notifications.
    # @return [JiraCache::Notifier]
    def self.notifier
      @notifier ||= JiraCache::Notifier.new(logger)
    end
  end
end
