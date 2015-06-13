module JiraCache
  class State

    class Document
      include Mongoid::Document
      include Mongoid::Timestamps

      store_in collection: 'sync.states'

      field :project_sync_times, type: Array

      def self.get
        @singleton = self.first || (
          new_state = self.new
          new_state.project_sync_times = {}
          new_state.save!
          new_state
        )
      end
    end

    def self.get_project_sync_time(project_key)
      Document.get.project_sync_times[project_key]
    end

    def self.set_project_sync_time(project_key, time)
      state = Document.get
      state.project_sync_times[project_key] = time
      state.save!
    end
  end
end
