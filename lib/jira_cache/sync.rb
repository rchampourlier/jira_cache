require 'jira_cache/issue'
require 'jira_cache/project_state'
require 'jira_cache/client'

module JiraCache
  module Sync
    THREAD_POOL_SIZE = ENV['JIRA_CACHE_THREAD_POOL_SIZE'] || 100

    # Fetches new and updated raw issues, save them
    # to the `issues` collection. Also mark issues
    # deleted from JIRA as such.
    #
    # @param project_key [String] the JIRA project key
    def run(client, project_key)
      sync_start = Time.now

      remote = remote_keys(client, project_key)
      cached = cached_keys(project_key)
      missing = remote - cached
      updated = updated_keys(client, project_key)

      fetch_issues(client, missing + updated)

      deleted = cached - remote
      mark_deleted(deleted)

      synced_project!(project_key, sync_start)
    end
    module_function :run

    # IMPLEMENTATION FUNCTIONS

    def remote_keys(client, project_key)
      fetch_issue_keys(client, project_key)
    end
    module_function :remote_keys

    def cached_keys(project_key)
      Issue.keys(project_key: project_key)
    end
    module_function :cached_keys

    def updated_keys(client, project_key)
      time = last_sync_time(project_key)
      fetch_issue_keys(client, project_key, updated_since: time)
    end
    module_function :updated_keys

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
      jql_query << " AND updatedDate > \"#{updated_since.strftime('%Y-%m-%d %H:%M')}\"" if updated_since
      client.issue_keys_for_query jql_query
    end
    module_function :fetch_issue_keys

    # @param client [JiraCache::Client]
    # @param issue_keys [Array] array of strings representing the JIRA keys
    def fetch_issues(client, issue_keys)
      pool = Thread.pool(THREAD_POOL_SIZE)
      issue_keys.each do |issue_key|
        pool.process do
          data = client.issue_data(issue_key)
          Issue.create_or_update data
        end
      end
      pool.shutdown
    end
    module_function :fetch_issues

    def mark_deleted(issue_keys)
      issue_keys.each do |issue_key|
        Issue.deleted_from_jira! issue_key
      end
    end
    module_function :mark_deleted

    def synced_project!(project_key, sync_time)
      ProjectState.synced_project! project_key, sync_time
    end
    module_function :synced_project!

    def last_sync_time(project_key)
      ProjectState.sync_time(project_key)
    end
    module_function :last_sync_time
  end
end
