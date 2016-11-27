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
    class << self
      THREAD_POOL_SIZE = (ENV["THREAD_POOL_SIZE"] || 100).to_i

      # Fetches new and updated raw issues, save them
      # to the `issues` collection. Also mark issues
      # deleted from JIRA as such.
      #
      # @param project_key [String] the JIRA project key
      def sync_project_issues(client, project_key)
        sync_start = Time.now

        remote = remote_keys(client, project_key)
        cached = cached_keys(project_key)
        missing = remote - cached
        updated = updated_keys(client, project_key)

        fetch_issues(client, missing + updated, sync_start)

        deleted = cached - remote
        mark_deleted(deleted)
      end

      def sync_issue(client, key, sync_time: Time.now)
        data = client.issue_data(key)
        Data::IssueRepository.insert(
          key: key,
          data: data,
          synced_at: sync_time
        )
      end

      # IMPLEMENTATION FUNCTIONS

      def remote_keys(client, project_key)
        fetch_issue_keys(client, project_key)
      end

      def cached_keys(project_key)
        Data::IssueRepository.keys_in_project(project_key)
      end

      def updated_keys(client, project_key)
        time = latest_sync_time(project_key)
        fetch_issue_keys(client, project_key, updated_since: time)
      end

      # Fetch from JIRA

      # Fetch issue keys from JIRA using the specified `JiraCache::Client`
      # instance, for the specified project, with an optional `updated_since`
      # parameter.
      #
      # @param client [JiraCache::Client]
      # @param project_key [String]
      # @param updated_since [Time]
      # @return [Array] array of issue keys as strings
      def fetch_issue_keys(client, project_key, updated_since: nil)
        jql_query = "project = \"#{project_key}\""
        jql_query += " AND updatedDate > \"#{updated_since.strftime('%Y-%m-%d %H:%M')}\"" if updated_since
        client.issue_keys_for_query jql_query
      end

      # @param client [JiraCache::Client]
      # @param issue_keys [Array] array of strings representing the JIRA keys
      def fetch_issues(client, issue_keys, sync_time)
        issue_keys.each do |issue_key|
          sync_issue(client, issue_key, sync_time: sync_time)
        end
      end

      def mark_deleted(issue_keys)
        Data::IssueRepository.update_where({ key: issue_keys }, deleted_from_jira_at: Time.now)
      end

      def latest_sync_time(project_key)
        Data::IssueRepository.latest_sync_time
      end
    end
  end
end
