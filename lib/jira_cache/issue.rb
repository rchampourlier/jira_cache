require 'mongoid'

module JiraCache

  # Document to store JIRA issue data.
  class Issue
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'issues'

    field :key,  type: String
    field :data, type: Hash
    field :deleted_from_jira_at, type: Time

    def self.find_by_key(issue_key)
      where(key: issue_key).first
    end

    def self.create_or_update(issue_data)
      issue_key = issue_data['key']
      doc = find_by_key(issue_key)
      doc ||= new
      doc.key = issue_key
      doc.data = issue_data
      doc.save!
      doc
    end

    def self.deleted_from_jira!(issue_key)
      issue = find_by_key(issue_key)
      issue.deleted_from_jira_at = Time.now
      issue.save!
    end

    # @param project_key [String] key of the JIRA project
    # @param deleted_from_jira [Boolean] include cached issues deleted from JIRA
    def self.keys(project_key: nil, deleted_from_jira: nil)
      criteria = {}

      criteria.merge!(
        project_key: { :$eq => project_key }
      ) if project_key

      criteria.merge!({
        # TODO: add the appropriate query criteria
        # deleted_from_jira_at:
      }) if deleted_from_jira

      only('key').map(&:key)
    end
  end
end
