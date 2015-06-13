require 'process'
require 'sync'

module JiraCache
  class Document
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'raw_issues'

    field :key,  type: String
    field :data, type: Hash
    field :deleted_from_jira_at, type: Time

    def self.find_by_key(issue_key)
      where(key: issue_key).first
    end

    def self.create_or_update(raw_data)
      issue_key = Process.read raw_data, 'key'
      doc = find_by_key(issue_key)
      doc ||= self.new
      doc.key = issue_key
      doc.data = raw_data
      doc.save!
      doc
    end

    def self.set_deleted_from_jira_for_key(issue_key)
      issue = self.find_by_key(issue_key)
      issue.deleted_from_jira_at = Time.now
      issue.save!
    end

    def self.keys(project_key: nil, deleted_from_jira: nil)
      criteria = {}

      criteria.merge!(
        project_key: { :$eq => project_key }
      ) if project_key

      criteria.merge!(
        # TODO add the appropriate query criteria
        #deleted_from_jira_at:
      ) if deleted_from_jira

      self.only('key').map(&:key)
    end
  end
end
