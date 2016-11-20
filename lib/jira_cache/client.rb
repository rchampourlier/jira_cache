# frozen_string_literal: true
require "rest-client"
require "base64"
require "jira_cache/notifier"

module JiraCache

  # The JIRA API Client.
  class Client
    JIRA_MAX_RESULTS = 1000

    EXPANDED_FIELDS = %w(
      renderedFields
      changelog
    ).freeze
    # Other possible fields: names, schema, operations, editmeta

    attr_reader :logger, :notifier

    # Returns a new instance of the client, configured with
    # the specified parameters.
    #
    # @param domain [String] JIRA API domain (e.g. your-project.atlassian.net)
    # @param username [String] JIRA user"s name, if required
    # @param password [String] JIRA user"s password, if required
    # @param logger [Logger] used to log message (defaults to a logger to STDOUT at
    #   info level)
    # @param notifier [Notifier] a notifier instance that will be used to publish
    #   event notifications (see `JiraCache::Notifier` for more information)
    #
    def initialize(domain:, username: nil, password: nil, notifier: nil, logger: nil)
      check_domain!(domain)
      check_password!(username, password)
      @domain = domain
      @username = username
      @password = password
      @logger = logger || default_logger
      @notifier = notifier || JiraCache::Notifier.new(@logger)
    end

    # Fetches the issue represented by id_or_key from the
    # client.
    # If the data is already present in the cache,
    # returns the cached version, unless if :allow_cache
    # option is false.
    def issue_data(id_or_key)
      logger.info "Fetching data for issue #{id_or_key}"
      issue_data = do_get("/issue/#{id_or_key}",
        expand: EXPANDED_FIELDS.join(",")
      ).to_hash
      return nil if issue_not_found?(issue_data)
      issue_data = complete_worklogs(id_or_key, issue_data)
      begin
        notifier.publish "fetched_issue", key: id_or_key, data: issue_data
      rescue => e
        logger.critical "Notifier failed: #{e}"
        logger.critical e.caller
      end
      issue_data
    end

    def issue_keys_for_query(jql_query)
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
      issues.collect { |issue| issue["key"] }
    end

    # Implementation methods
    # ======================

    # @return [total, issues]
    #   - total: [Int] the total number of issues in the query results
    #   - issues: [Array] array of issues in the response
    #     (max `JIRA_MAX_RESULTS`)
    def issue_ids_in_limits(jql_query, start_at)
      results = do_get "/search",
        jql: jql_query,
        startAt: start_at,
        fields: "id",
        maxResults: JIRA_MAX_RESULTS
      [results["total"], results["issues"]]
    end

    def issue_not_found?(issue_data)
      return false if issue_data["errorMessages"].nil?
      issue_data["errorMessages"].first == "Issue Does Not Exist"
    end

    def complete_worklogs(id_or_key, issue_data)
      if incomplete_worklogs?(issue_data)
        issue_data["fields"]["worklog"] = issue_worklog_content(id_or_key)
      end
      issue_data
    end

    def incomplete_worklogs?(issue_data)
      worklog = issue_data["fields"]["worklog"]
      worklog["total"].to_i > worklog["maxResults"].to_i
    end

    def issue_worklog_content(id_or_key)
      do_get("/issue/#{id_or_key}/worklog").to_hash
    end

    def project_data(id)
      do_get "/project/#{id}"
    end

    def projects_data
      do_get "/project"
    end

    def do_get(path, params = {})
      logger.debug "GET #{uri(path)} #{params}"
      response = RestClient.get uri(path),
        params: params,
        content_type: "application/json"
      begin
        JSON.parse(response.body)
      rescue JSON::ParseError
        response.body
      end
    end

    # Returns the JIRA API"s base URI (build using `config[:domain]`)
    def uri(path)
      "https://#{authorization_prefix}#{@domain}/rest/api/2#{path}"
    end

    def authorization_prefix
      return "" if missing_credential?
      "#{CGI.escape(@username)}:#{CGI.escape(@password)}@"
    end

    def default_logger
      logger = ::Logger.new(STDOUT)
      logger.level = ::Logger::FATAL
      logger
    end

    # Returns an hash of info on the client
    def info
      {
        domain: @domain,
        username: @username
      }
    end

    private

    def check_domain!(domain)
      raise "Missing domain" if domain.nil? || domain.empty?
    end

    def check_password!(username, password)
      unless (username.nil? || username.empty?)
        raise "Missing password (mandatory if username given)" if password.nil? || password.empty?
      end
    end

    def missing_credential?
      return true if @username.nil? || @username.empty?
      return true if @password.nil? || @password.empty?
      false
    end
  end
end
