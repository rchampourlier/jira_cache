require 'thread/pool'
require 'jira_cache/version'
require 'jira_cache/sync'

# Facility to store/cache JIRA issues data in a MongoDB datastore.
#
# Currently provides a single method to perform the synchronization,
# `JiraCache::sync_project_issues(project_key)`.
module JiraCache

  def sync_issues(client, project_key)
    Sync.run(client, project_key)
  end
  module_function :sync_issues
end
