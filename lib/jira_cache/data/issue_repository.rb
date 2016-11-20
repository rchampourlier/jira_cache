# frozen_string_literal: true
require "data"
require "active_support/inflector"

module JiraCache
  module Data

    # Superclass for repositories. Simply provide some shared
    # methods.
    class IssueRepository

      # It inserts a new issue row with the specified data.
      # If the issue already exists (checking on the "key"),
      # the row is updated instead.
      def self.insert(key:, data:, synced_at:, deleted_from_jira_at: nil)
        attributes = {
          key: key,
          data: Sequel.pg_json(data),
          synced_at: synced_at,
          deleted_from_jira_at: deleted_from_jira_at
        }
        if exist_with_key?(key)
          update_where({ key: key }, attributes)
        else
          table.insert row(attributes)
        end
      end

      def self.find_by_key(key)
        table.where(key: key).first
      end

      def self.exist_with_key?(key)
        table.where(key: key).count != 0
      end

      def self.keys_in_project(project_key)
        table.where("(data ->> 'project') = ?", project_key).select(:key).map(&:values).flatten
      end

      def self.delete_where(where_data)
        table.where(where_data).delete
      end

      def self.update_where(where_data, values)
        table.where(where_data).update(values)
      end

      def self.first_where(where_data)
        table.where(where_data).first
      end

      def self.index
        table.entries
      end

      def self.count
        table.count
      end

      def self.latest_sync_time
        table.order(:synced_at).select(:synced_at).last&.dig(:synced_at)
      end

      def self.keys_for_deleted_issues
        table.where("deleted_from_jira_at IS NOT NULL")
          .select(:key)
          .map(&:values)
          .flatten
      end

      def self.row(attributes, time = nil)
        time ||= Time.now
        attributes.merge(
          created_at: time,
          updated_at: time
        )
      end

      def self.table
        DB[:jira_cache_issues]
      end
    end
  end
end
