require 'logstash/event'
require 'forwardable'

module LogStash; module PluginMixins; module EventSupport

  # `LogStash::Event` decorator which supports most of the event API.
  # Values end up being stored in a (prefix hash) target namespace.
  #
  # @note Internal references (starting with `@`) e.g. `@timestamp` or
  # `@metadata` are respected and thus are NOT namespaced.
  class EventTargetDecorator
    extend Forwardable

    def self.wrap(event, target_namespace = nil)
      self.new(event, target_namespace)
    end

    def initialize(event, target_namespace)
      @event = event
      namespace = target_namespace.to_s.strip
      if namespace.empty? || namespace.start_with?('[')
        @target_ns = namespace
      else
        @target_ns = "[#{namespace}]"
      end
    end

    # Event interface

    def_delegators :@event, :cancel, :uncancel, :cancelled?, :clone # no args
    def_delegators :@event, :to_s, :to_hash, :to_hash_with_metadata, :to_json
    def_delegators :@event, :tag, :timestamp, :timestamp=

    # @return value at [target_namespace][ref]
    #
    # @note Internal references @timestamp and @metadata are NOT namespaced.
    def get(ref)
      @event.get(target_ref(ref))
    end

    # @return set value
    #
    # @note Internal references @timestamp and @metadata are NOT namespaced.
    def set(ref, value)
      @event.set(target_ref(ref), value)
    end

    # @return whether reference is present in event
    #
    # @note Internal references @timestamp and @metadata are NOT namespaced.
    def include?(ref)
      @event.include?(target_ref(ref))
    end

    # Removes a mapping from the event.
    #
    # @note Internal references @timestamp and @metadata are NOT namespaced.
    def remove(ref)
      @event.remove(target_ref(ref))
    end

    # Appends data from given event to this event.
    # @return self
    def append(event)
      if @target_ns.empty?
        namespaced_event = event
      else
        namespaced_event = LogStash::Event.new
        namespaced_event.set @target_ns, event.to_hash
      end
      @event.append(namespaced_event) # only data is appended
      self
    end

    # Overwrite event from another.
    # @return self
    #
    # @note In this case target namespace is not maintained.
    def overwrite(event)
      # TODO unclear whether we really need this to retain namespace when overwriting, might be confusing?!?
      @event.overwrite(event)
      self
    end

    # @note Not supported due the difficulty of arbitrary reference resolution.
    def sprintf(format)
      raise NotImplementedError.new("#{self.class} does not support Event#sprintf")
    end

    # Custom

    def __unwrap__
      @event
    end
    alias unwrap __unwrap__

    private

    def target_ref(ref)
      ref = ref.to_str
      return ref if internal_ref?(ref)

      if ref.start_with?('[')
        @target_ns + ref
      else
        "#{@target_ns}[#{ref}]"
      end
    end

    def internal_ref?(ref)
      ref.start_with?('@') || ref.start_with?('[@')
    end

  end

end end end
