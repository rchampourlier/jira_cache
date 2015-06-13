require 'sync/state'
require 'sync/client'

module JiraCache

  # Use `Sync.sync_project_issues(project_key)`
  # to sync all issues of the corresponding projects.
  class Sync

    def self.sync_project_raw_issues(project_key)
      sync_start = Time.now
      sync_raw_issues(project_key)
      set_synced_at(sync_start)
    end

    private

    # Fetches new and updated raw issues, save them
    # to the `raw_issues` collection. Also mark issues
    # deleted from JIRA as such.
    def self.sync_raw_issues(project_key)
      remote_issue_keys = fetch_project_issue_keys(project_key)
      local_issue_keys = find_project_issue_keys(project_key, deleted: false)
      missing_issue_keys = remote_issue_keys - local_issue_keys

      remote_updated_issue_keys = fetch_project_issue_keys project_key, updated_since: last_sync_time(project_key)

      needing_update_issue_keys = (missing_issue_keys + remote_updated_issue_keys).uniq
      needing_update_issue_keys.each do |needing_update_issue_key|
        update_issue_with_key(needing_update_issue_key)
      end

      deleted_issue_keys = local_issue_keys - remote_issue_keys
      deleted_issue_keys.each do |deleted_issue_key|
        mark_issue_deleted(deleted_issue_key)
      end
    end

    def self.mark_issue_deleted(issue_key)
      RawIssue.set_deleted_for_key deleted_issue_key
    end

    def self.find_project_issue_keys(project_key, deleted: deleted)
      RawIssue.issue_keys(
        project_key: project_key,
        deleted: deleted
      )
    end

    def self.set_synced_at(sync_start)
      State.set_project_sync_time project_key, sync_start
    end

    # IMPLEMENTATION

    def self.last_sync_time(project_key)
      State.get_project_sync_time(project_key)
    end

    def self.update_issue_with_key(issue_key)
      data = Client.issue_data(issue_key)
      RawIssue.create_or_update data
    end

    def self.fetch_project_issue_keys(project_key, updated_since: updated_since)
      jql_query = "project = \"#{project_key}\""
      jql_query << " AND updatedDate > \"#{updated_since.strftime('%Y-%m-%d %H:%M')}\"" if updated_since
      Client.issue_keys_for_query jql_query
    end
  end
end
