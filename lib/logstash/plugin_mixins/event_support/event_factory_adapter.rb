# encoding: utf-8

require 'logstash/plugin_mixins/event_support'

require 'logstash-core'
require 'logstash/plugin'

module LogStash
  module PluginMixins
    module EventSupport
      module EventFactoryAdapter

        ##
        # @api internal
        # @param base [Class]: a class that inherits `LogStash::Plugin`, typically one
        #                      descending from one of the four plugin base classes
        #                      (e.g., `LogStash::Inputs::Base`)
        # @return [void]
        def self.included(base)
          fail(ArgumentError, "`#{base}` must inherit LogStash::Plugin") unless base < LogStash::Plugin

          if defined? LogStash::Plugins::EventFactorySupport
            core_event_support = LogStash::Plugins::EventFactorySupport
            fail(ArgumentError, "`#{base}` should include #{core_event_support}") unless base < core_event_support
          else
            require 'logstash/plugin_mixins/event_support/event_factory_adapter/fallback_impl'
            base.send(:include, FallbackImpl)
            private_constant :FallbackImpl
          end
        end

        ##
        # @api private
        #
        # @param base [Object]
        # @raise [ArgumentError]
        def self.extended(base)
          fail(ArgumentError, "`#{self}` cannot be extended into an existing object (#{base.inspect})")
        end

      end
    end
  end
end
