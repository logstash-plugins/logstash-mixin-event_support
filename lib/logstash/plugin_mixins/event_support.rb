require 'logstash/namespace'
require 'logstash/event'

require 'logstash/plugin_mixins/event_support/event_factory'
require 'logstash/plugin_mixins/event_support/event_target_decorator'

module LogStash
  module PluginMixins
    module EventSupport

      def event_factory
        @_event_factory ||=
          if ecs_compatibility?
            EventFactory::INSTANCE
          else
            LegacyEventFactory::INSTANCE
          end
      end

      def event_factory=(factory)
        @_event_factory = factory
      end

      # Creates a new event using the set event factory.
      # @param target_namespace an optional namespace (prefix) for data in event
      # @param event_factory
      # @return [LogStash::Event]
      def new_event(data = {}, target_namespace: nil, event_factory: self.event_factory)
        return event_factory.new_event(data) unless target_namespace

        # NOTE: might be more performant to create event using all data and use move_event_data helper
        init_data = data.select { |key, _| key.start_with?('@') || key.start_with?('[@') } # @timestamp, [@metadata][foo]
        event = event_factory.new_event(init_data)
        target = '[' + target_namespace.split(/\[(.*)\]/).join + ']'
        data.slice(*(data.keys - init_data.keys)).each do |key, val|
          key = "[#{key}]" unless key.index('[')
          event.set(target + key, val)
        end
        event
      end

      private

      def with_namespace(event, target_namespace)
        if target_namespace.nil? || target_namespace.empty?
          yield event
        else
          yield EventTargetDecorator.wrap(event, target_namespace)
        end
      end

      # Move all event data under given namespace (prefix).
      #
      # All field mappings, except for internal keys such as @timestamp and @metadata,
      # will be moved under a target namespace e.g.
      #
      #   'foo' => 'bar'  ->  '[target][foo]' => 'bar'
      #
      # @note The passed event gets modified in place.
      def move_event_data(event, target_namespace)
        return if target_namespace.nil? || target_namespace.empty?

        event_data = event.to_hash

        empty_proto = LogStash::Event.new '@timestamp' => event.timestamp
        empty_proto.cancel if event.cancelled?
        event_data.reject! do |key, val|
          if key.start_with?('@')
            empty_proto.set(key, val) || true
          end
        end

        event.overwrite(empty_proto)
        event.set(target_namespace, event_data)
      end

    end
  end
end
