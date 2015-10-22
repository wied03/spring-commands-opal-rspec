require 'spring/application'

# Out of the box, there is no way to send any state back from a command to the application class
# We spin up another server process that needs to be terminated when the app process terminates
module Spring
  class Application
    def setup(command_wrapper)
      setup = if command_wrapper.command.is_a?(Spring::Commands::OpalRSpec)
                pid = command_wrapper.command.setup
                @opal_rspec_pid ||= pid
              else
                command_wrapper.setup
              end
      if setup
        watcher.add loaded_application_features # loaded features may have changed
      end
    end

    alias_method :stock_terminate, :terminate

    def terminate
      if @opal_rspec_pid
        log "terminating opal-rspec PID #{@opal_rspec_pid}"
        Process.kill 'TERM', @opal_rspec_pid
      end
      stock_terminate
    end
  end
end
