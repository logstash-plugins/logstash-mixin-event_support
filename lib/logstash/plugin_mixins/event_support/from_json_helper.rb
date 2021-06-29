# encoding: utf-8

require 'logstash/plugin_mixins/event_support'
require 'logstash/plugin_mixins/event_support/event_factory_adapter'

require 'logstash-core'
require 'logstash/event'

module LogStash
  module PluginMixins
    module EventSupport
      module FromJsonHelper

        def self.included(base)
          if defined? LogStash::Plugins::EventFactorySupport # native support from LS core
            base.send(:include, NativeImpl)
          else
            require 'logstash/json'
            base.send(:include, FallbackImpl)
          end
        end

        module NativeImpl

          def events_from_json(json, event_factory)
            LogStash::Event.from_json(json) { |data| event_factory.new_event(data) }
          end

        end
        private_constant :NativeImpl

        module FallbackImpl

          def events_from_json(json, event_factory)
            decoded = LogStash::Json.load(json)
            case decoded
            when Array then decoded.map { |data| event_factory.new_event(data) }
            when Hash  then [ event_factory.new_event(decoded) ]
            when nil   then [] # same behavior as Event.from_json("")
            else raise LogStash::Json::ParserError.new("JSON must contain array or hash, got #{decoded.class}")
            end
          end

        end
        private_constant :FallbackImpl

      end
    end
  end
end
