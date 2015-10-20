# -*- encoding: utf-8 -*-
require File.expand_path('../lib/spring-commands-orspec/version', __FILE__)

Gem::Specification.new do |s|
  s.name         = 'spring-commands-orspec'
  s.version      =  SpringCommandsOrspec::VERSION
  s.author       = 'Brady Wied'
  s.email        = 'brady@bswtechconsulting.com'
  s.summary      = 'Adds spring support to opal-rspec'
  s.description  = 'Allows the opal-rspec Rake task to run faster by keeping the PhantomJS process running in the background'
  s.homepage     = 'https://github.com/wied03/spring-commands-orspec'

  s.files = `git ls-files`.split("\n")

  s.require_paths  = ['lib']

  s.add_dependency 'opal-rspec', '>= 0.5.0.beta2'
  s.add_development_dependency 'rake'
end
