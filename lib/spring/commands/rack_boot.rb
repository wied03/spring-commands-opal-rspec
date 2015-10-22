Process.setsid
require 'bundler'
require 'spring/commands/orspec'
require 'rack'
require 'webrick'
require File.expand_path('config/environment', ENV['RAILS_ROOT'])

pattern = ENV['PATTERN'] || (::Rails.application.config.opal.spec_location+'/**/*_spec{,.js}.{rb,opal}')
sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern = pattern)
app = Opal::Server.new(sprockets: sprockets_env) { |s|
  s.main = 'opal/rspec/sprockets_runner'
  s.debug = false

  ::Rails.application.assets.paths.each { |p| s.append_path p }
}
sprockets_env.add_spec_paths_to_sprockets
app_name = ::Spring::Env.new.app_name

Spring::ProcessTitleUpdater.run { |distance|
  "spring app    | #{app_name} | started #{distance} ago | opal-rspec mode"
}

Rack::Server.start(
    :app => app,
    :Port => Spring::Commands::Orspec::PORT,
    :AccessLog => [],
    :Logger => WEBrick::Log.new("/dev/null"),
)
