# History

## 2017-02-19 - 0.2.0

- Supporting fetching of all issues without filtering on a specific project key.
- Simplified interface by relying to default values for notifier, client...
  using environment variables to configure them.

Interface changes:

- `JiraCache.sync_project_issues(client, project_key)` becomes
  `JiraCache.sync_issues(client: client, project_key: project_key)`.
- `JiraCache.sync_issue(client, issue_key)` becomes
  `JiraCache.sync_issue(issue_key, client: client)`.
- `JiraCache::Sync.sync_project_issues(project_key)` becomes 
  `JiraCache::Sync.sync_issues(project_key: project_key)`.
- `JiraCache.sync_issue(client, 'issue_key')` becomes
  `JiraCache.sync_issue('issue_key', client: client)`.
- The webhook app may now be run using `run JiraCache.webhook_app`
  instead of `...webhook_app(client)` if the default client may be
  used (configured using environment variables).

