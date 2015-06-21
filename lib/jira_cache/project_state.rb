require 'mongoid'

module JiraCache

  # Per-proejct document storing project's state (in particular sync time).
  class ProjectState
    include Mongoid::Document
    store_in collection: 'project_states'

    field :project_key, type: String
    field :synced_at, type: Time

    def self.sync_time(project_key)
      latest = where(project_key: project_key).order_by(:synced_at.desc).first
      latest ? latest.synced_at : nil
    end

    def self.synced_project!(project_key, time)
      create!(project_key: project_key, synced_at: time)
    end
  end
end
