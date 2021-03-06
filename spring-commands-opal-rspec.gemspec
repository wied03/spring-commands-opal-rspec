# -*- encoding: utf-8 -*-
require File.expand_path('../lib/spring/commands/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'spring-commands-opal-rspec'
  s.version = Spring::Commands::OpalRSpec::VERSION
  s.author = 'Brady Wied'
  s.email = 'brady@bswtechconsulting.com'
  s.summary = 'Adds spring support to opal-rspec'
  s.description = 'Allows the opal-rspec Rake task to run faster by keeping the PhantomJS process running in the background'
  s.homepage = 'https://github.com/wied03/spring-commands-orspec'

  s.files = Dir.glob('lib/**/*.rb')

  s.require_paths = ['lib']

  s.add_dependency 'opal-rspec', '>= 0.5.0.beta3'
  s.add_dependency 'opal-rails', '>= 0.8.1'
  s.add_dependency 'spring', '>= 0.9.1'
  s.add_development_dependency 'rake'

  s.add_development_dependency 'rspec-rails', '~> 3.0'
end
