require_relative '../../spec_helper'

require "logstash/plugin_mixins/event_support/from_json_helper"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'

describe LogStash::PluginMixins::EventSupport::FromJsonHelper do

  context 'included into a class' do

    [
        LogStash::Inputs::Base,
        LogStash::Filters::Base,
        LogStash::Codecs::Base,

    ].each do |base_class|

      context "that inherits from `#{base_class}`" do

        subject(:plugin_class) do
          Class.new(base_class) do
            config_name 'sample'

            include LogStash::PluginMixins::EventSupport::FromJsonHelper
          end
        end

        let(:options) { Hash.new }
        let(:plugin) { plugin_class.new(options) }

        let(:event_factory) { double('event_factory') }

        it 'parses valid json' do
          expect( event_factory ).to receive(:new_event) { |data| LogStash::Event.new('test' => data) }

          events = plugin.events_from_json('{ "foo": "bar" }', event_factory)
          expect( events.size ).to eql 1
          expect( event = events.first ).to be_a LogStash::Event
          expect( event.get('[test]') ).to eql 'foo' => 'bar'
        end

        it 'parses multi json' do
          expect( event_factory ).to receive(:new_event) { |data| LogStash::Event.new('test' => data) }.twice

          events = plugin.events_from_json('[ {"foo": "bar"}, { "baz": 42.0 } ]', event_factory)
          expect( events.size ).to eql 2
          expect( events[0].get('[test]') ).to eql 'foo' => 'bar'
          expect( events[1].get('[test]') ).to eql 'baz' => 42.0
        end

        it 'does not raise on blank strings' do
          events = plugin.events_from_json('', event_factory)
          expect( events.size ).to eql 0
          events = plugin.events_from_json("  ", event_factory)
          expect( events.size ).to eql 0
          events = plugin.events_from_json("\n", event_factory)
          expect( events.size ).to eql 0
        end

        it 'raises on unexpected json' do
          expect { plugin.events_from_json(' "42" ', event_factory) }.to raise_error(LogStash::Json::ParserError)
        end

        it 'raises on invalid json' do
          expect { plugin.events_from_json('{ "" }', event_factory) }.to raise_error(LogStash::Json::ParserError)
        end
        
        it 'raises on incomplete json' do
          expect { plugin.events_from_json('{"answer":"42"', event_factory) }.to raise_error(LogStash::Json::ParserError)
        end

      end

    end
  end
end
