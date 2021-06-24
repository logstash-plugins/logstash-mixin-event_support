require_relative '../../spec_helper'

require "logstash/plugin_mixins/event_support/event_factory_adapter"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'

describe LogStash::PluginMixins::EventSupport::EventFactoryAdapter do
  let(:event_factory_adapter) { described_class }

  context 'included into a class' do

    context 'that does not inherit from `LogStash::Plugin`' do
      let(:plugin_class) { Class.new }
      it 'fails with an ArgumentError' do
        expect do
          plugin_class.send(:include, described_class)
        end.to raise_error(ArgumentError, /LogStash::Plugin/)
      end
    end

    [
        LogStash::Inputs::Base,
        LogStash::Filters::Base,
        LogStash::Codecs::Base,
        LogStash::Outputs::Base
    ].each do |base_class|

      context "that inherits from `#{base_class}`" do

        # native_event_factory_support = base_class.method_defined?(:event_factory)

        let(:plugin_base_class) { base_class }

        subject(:plugin_class) do
          Class.new(plugin_base_class) do
            config_name 'sample'
          end
        end

        describe 'the result' do

          before(:each) do
            plugin_class.send(:include, described_class)
          end

          it 'defines an `event_factory` method' do
            expect(plugin_class.method_defined?(:event_factory)).to be true
          end

          it 'defines an `targeted_event_factory` method' do
            expect(plugin_class.method_defined?(:targeted_event_factory)).to be true
          end

          let(:options) { Hash.new }
          let(:plugin) { plugin_class.new(options) }

          shared_examples 'an event factory' do

            it 'returns an event' do
              expect( event_factory.new_event ).to be_a LogStash::Event
              expect( event = event_factory.new_event('foo' => 'bar') ).to be_a LogStash::Event
              expect( event.get('foo') ).to eql 'bar'
            end

          end

          describe 'event_factory' do

            subject(:event_factory) { plugin.send(:event_factory) }

            it_behaves_like 'an event factory'

            it 'memoizes the factory instance' do
              expect( event_factory ).to be plugin.send(:event_factory)
            end

          end

          describe 'targeted_event_factory (no config :target option)' do

            it 'raises an error' do
              expect { plugin.send(:targeted_event_factory) }.to raise_error(ArgumentError, /target/)
            end

          end

          describe 'targeted_event_factory' do

            subject(:plugin_class) do
              Class.new(plugin_base_class) do
                config_name 'sample'
                config :target, :validate => :string
              end
            end

            subject(:event_factory) { plugin.send(:targeted_event_factory) }

            it_behaves_like 'an event factory'

            it 'memoizes the factory instance' do
              expect( event_factory ).to be plugin.send(:targeted_event_factory)
            end

            it 'uses the basic event factory (no target specified)' do
              expect( event_factory ).to be plugin.send(:event_factory)
            end

            context 'with target' do

              let(:options) { super().merge('target' => '[the][baz]') }

              it 'returns an event' do
                expect( event_factory.new_event ).to be_a LogStash::Event
                expect( event = event_factory.new_event('foo' => 'bar') ).to be_a LogStash::Event
                expect( event.include?('foo') ).to be false
                expect( event.get('[the][baz][foo]') ).to eql 'bar'
              end

              it 'memoizes the factory instance' do
                expect( event_factory ).to be plugin.send(:targeted_event_factory)
              end

              it 'uses a different factory from the basic one' do
                expect( event_factory ).not_to be plugin.send(:event_factory)
              end

            end
          end

        end
      end
    end

  end
end
