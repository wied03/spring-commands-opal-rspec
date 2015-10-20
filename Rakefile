Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'opal/rspec/rake_task'

Opal::RSpec::RakeTask.new(:raw_specs) do |_, task|
  task.pattern = 'spec/opal/**/*_spec.rb'
end
RSpec::Core::RakeTask.new(:default) do |s|
  s.pattern = 'spec/mri/**/*_spec.rb'
end
