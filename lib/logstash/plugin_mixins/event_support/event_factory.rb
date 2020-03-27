require 'logstash/event'

module LogStash; module PluginMixins; module EventSupport

  class EventFactory

    INSTANCE = new

    def new_event(data = {})
      event = LogStash::Event.new(data)
      normalize(event, data)
      event
    end

    def normalize(event, data = nil)
      return if event.include?('event.created')

      if data.nil? || data['@timestamp']
        created = LogStash::Timestamp.now
      else
        created = event.timestamp
      end
      event.set('event.created', created)
    end

  end

  class LegacyEventFactory

    INSTANCE = new

    def new_event(data = {})
      LogStash::Event.new(data)
    end

    def normalize(event, data = nil)
      # no-op
    end

  end

end end end
