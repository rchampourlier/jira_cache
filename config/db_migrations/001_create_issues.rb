#!/usr/bin/env ruby
# frozen_string_literal: true

Sequel.migration do
  up do
    create_table :jira_cache_issues do
      String :key
      column :data, "json"
      DateTime :synced_at
      DateTime :deleted_from_jira_at

      # Timestamps
      DateTime :created_at
      DateTime :updated_at
    end
  end

  down do
    drop_table(:jira_cache_issues)
  end
end
