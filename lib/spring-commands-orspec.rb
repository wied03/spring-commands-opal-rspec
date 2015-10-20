puts 'run'
if defined?(Spring.register_command)
  puts 'requiring'
  require 'spring/commands/orspec'
end
