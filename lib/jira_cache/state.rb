require 'mongoid'

module JiraCache
  class State
    include Mongoid::Document
    store_in collection: 'states'

    field :project_key, type: String
    field :sync_time, type: Time

    def self.project_sync_time(project_key)
      latest = order_by(:sync_time.desc).first
      latest ? latest.sync_time : nil
    end

    def self.synced_project!(project_key, time)
      create!(project_key: project_key, sync_time: time)
    end
  end
end
