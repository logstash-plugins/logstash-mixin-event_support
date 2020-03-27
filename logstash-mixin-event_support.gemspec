Gem::Specification.new do |s|
  s.name          = 'logstash-mixin-event_support'
  s.version       = '0.1.0'
  s.licenses      = %w(Apache-2.0)
  s.summary       = "Event support for Logstash plugins"
  s.authors       = %w(Elastic)
  s.email         = 'info@elastic.co'
  s.homepage      = 'https://github.com/logstash-plugins/logstash-mixin-event_support'
  s.require_paths = %w(lib)

  s.files = %w(lib spec vendor).flat_map{|dir| Dir.glob("#{dir}/**/*")}+Dir.glob(["*.md","LICENSE"])

  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.platform = RUBY_PLATFORM

  s.add_runtime_dependency 'logstash-core', '>= 6.3'

  s.add_development_dependency 'rspec', '~> 3.9'
end
