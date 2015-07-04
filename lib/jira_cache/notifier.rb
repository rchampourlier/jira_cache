module JiraCache

  # This notifiers simply logs messages using the specified
  # logger.
  #
  # If you want to use this mechanism to trigger actions when
  # events are triggered in JiraCache, you can use the
  # `JiraCache::Client.set_notifier(notifier)` method and pass
  # it an instance of a notifier class implementing the
  # `#publish` method with the same signature as
  # `JiraCache::Notifier#publish`.
  class Notifier

    # Initializes a notifier with the specified logger. The
    # logger is used to log info messages when #publish
    # is called.
    def initialize(logger)
      @logger = logger
    end

    # Simply logs the event name and data.
    def publish(event_name, data = nil)
      @logger.info "[#{event_name}] #{data}"
    end
  end
end
