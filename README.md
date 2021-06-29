# Event Support Mixin

[![Build Status](https://travis-ci.com/logstash-plugins/logstash-mixin-event_support.svg?branch=master)](https://travis-ci.com/logstash-plugins/logstash-mixin-event_support)


## Usage

1. Add this gem as a runtime dependency of your Logstash plugin's `gemspec`:

    ~~~ ruby
    Gem::Specification.new do |s|
      # ...

      s.add_runtime_dependency 'logstash-mixin-event_support'
    end
    ~~~

2. In your plugin code, require this library and include it into your plugin class
   that already inherits `LogStash::Plugin`:

    ~~~ ruby
    require 'logstash/plugin_mixins/event_support/event_factory_adapter'

    class LogStash::Codecs::Bar < Logstash::Codecs::Base

      include LogStash::PluginMixins::EventSupport::EventFactoryAdapter
   
      # an optional mixin to provide `events_from_json` using the factory :
      #include LogStash::PluginMixins::EventSupport::FromJsonHelper
   
      def decode(data, &block)
        payload = extract_bar(data) # ...
        yield event_factory.new_event(payload)
      end
   
      # def extract_bar(data) ...
   
    end
    ~~~

## Development

This gem:
 - *MUST* remain API-stable at 1.x
 - *MUST NOT* introduce additional runtime dependencies
