# frozen_string_literal: true
require "jira_cache/data/issue_repository"
require "jira_cache/client"

module JiraCache

  # Performs the sync between JIRA and the local database
  # where the issues are cached.
  #
  # The issues are cached in the database through the
  # Data::IssueRepository interface. It currently implements
  # storage into a PostgreSQL database.
  class Sync
    attr_reader :client, :logger

    def initialize(client)
      @client = client
      @logger = client.logger
    end

    # Fetches new and updated raw issues, save them
    # to the `issues` collection. Also mark issues
    # deleted from JIRA as such.
    #
    # @param project_key [String] the JIRA project key
    def sync_issues(project_key: nil)
      sync_start = Time.now

      log "Determining which issues to fetch..."
      remote = remote_keys(project_key: project_key)
      log "  - #{remote.count} remote issues"

      cached = cached_keys(project_key: project_key)
      log "  - #{cached.count} cached issues"

      missing = remote - cached
      log "  => #{missing.count} missing issues"

      updated = updated_keys(project_key: project_key)
      log "  - #{updated.count} updated issues"

      log "Fetching #{missing.count + updated.count} issues"
      fetch_issues(missing + updated, sync_start)

      deleted = cached - remote
      mark_deleted(deleted)
    end

    def sync_issue(key, sync_time: Time.now)
      data = client.issue_data(key)
      Data::IssueRepository.insert(
        key: key,
        data: data,
        synced_at: sync_time
      )
    end

    # IMPLEMENTATION FUNCTIONS

    def remote_keys(project_key: nil)
      fetch_issue_keys(project_key: project_key)
    end

    def cached_keys(project_key: nil)
      Data::IssueRepository.keys_in_project(project_key)
    end

    def updated_keys(project_key: nil)
      time = latest_sync_time(project_key: project_key)
      fetch_issue_keys(project_key: project_key, updated_since: time)
    end

    # Fetch from JIRA

    # Fetch issue keys from JIRA using the specified `JiraCache::Client`
    # instance, for the specified project, with an optional `updated_since`
    # parameter.
    #
    # @param project_key [String]
    # @param updated_since [Time]
    # @return [Array] array of issue keys as strings
    def fetch_issue_keys(project_key: nil, updated_since: nil)
      query_items = []
      query_items << "project = \"#{project_key}\"" unless project_key.nil?
      query_items << "updatedDate > \"#{updated_since.strftime('%Y-%m-%d %H:%M')}\"" unless updated_since.nil?
      query = query_items.join(" AND ")
      client.issue_keys_for_query(query)
    end

    # @param issue_keys [Array] array of strings representing the JIRA keys
    def fetch_issues(issue_keys, sync_time)
      issue_keys.each do |issue_key|
        sync_issue(issue_key, sync_time: sync_time)
      end
    end

    def mark_deleted(issue_keys)
      Data::IssueRepository.update_where({ key: issue_keys }, deleted_from_jira_at: Time.now)
    end

    def latest_sync_time(project_key)
      Data::IssueRepository.latest_sync_time
    end

    def log(message)
      return if logger.nil?
      logger.info(message)
    end
  end
end
