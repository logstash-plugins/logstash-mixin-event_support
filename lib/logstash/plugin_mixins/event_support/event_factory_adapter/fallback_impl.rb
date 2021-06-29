# encoding: utf-8

module LogStash::PluginMixins::EventSupport::EventFactoryAdapter::FallbackImpl

  # The event_factory method is effectively final and should not be re-defined by plugins.
  #
  # @return an event factory object with a `new_event(Hash)` API
  def event_factory
    @_event_factory ||= BasicEventFactory::INSTANCE
  end

  # The `targeted_event_factory` method is effectively final and should not be re-defined.
  # If the plugin defines a `target => ...` option than this method will return a factory
  # that respects the set target, otherwise (no target) returns {#event_factory}.
  #
  # @return an event factory object with a `new_event(Hash)` API
  def targeted_event_factory
    @_targeted_event_factory ||= begin # not synchronized - fine to initialize twice
                                   raise ArgumentError.new('config(:target) not present') unless respond_to?(:target)
                                   target.nil? ? event_factory : TargetedEventFactory.new(event_factory, target)
                                 end
  end

  private

  class BasicEventFactory
    INSTANCE = new

    # @param payload [Hash]
    # @return [LogStash::Event]
    def new_event(payload = {})
      LogStash::Event.new(payload)
    end

  end
  private_constant :BasicEventFactory

  class TargetedEventFactory

    def initialize(inner, target)
      @delegate = inner
      @target = target # TODO validate
    end

    # @param payload [Hash]
    # @return [LogStash::Event]
    def new_event(payload = {})
      event = @delegate.new_event
      event.set(@target, payload)
      event
    end

  end
  private_constant :TargetedEventFactory

end
