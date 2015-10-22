require 'spring/application'
require 'spring/commands'
require 'opal/rspec/rake_task'

module Spring
  class Application
    def setup(command_wrapper)
      setup = if command_wrapper.command.is_a?(Spring::Commands::Orspec)
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

module Spring
  module Commands
    class Orspec
      def env(*)
        'test'
      end

      def setup
        unless server_running?
          start_server
        end
      end

      def call
        wait_for_server
        launch_phantom
      end

      PORT = 9999
      URL = "http://localhost:#{PORT}/"

      def launch_phantom(timeout_value=nil)
        # TODO: Hard coded GEM path
        # Not using use_gem because we don't want the RSpec dependencies rspec_junit_formatter has
        #rspec_path = Gem::Specification.find_by_name('opal-rspec')
        path = '/usr/local/bundle/gems/opal-rspec-0.5.0.beta3'
        runner_path = File.join(path, 'vendor/spec_runner.js')

        if `phantomjs -v`.strip.to_i >= 2
          warn <<-WARN.gsub(/^              /, '')
                            Only PhantomJS v1 is currently supported,
                            if you're using homebrew on OSX you can switch version with:

                              brew switch phantomjs 1.9.8

          WARN
          exit 1
        end
        command_line = %Q{phantomjs #{runner_path} "#{URL}"#{timeout_value ? " #{timeout_value}" : ''}}
        puts "Running #{command_line}"
        system command_line
        success = $?.success?
        exit 1 unless success
      end

      def start_server
        pid = Process.spawn({'RAILS_ROOT' => ::Rails.root.to_s}, 'ruby',
                            "-I", File.expand_path("../..", __FILE__),
                            '-e',
                            'require "spring/commands/rack_boot"')
        puts "in #{Process.pid}, spawned server as #{pid}"
        pid
      end

      # TODO: dedupe with wait for server
      def server_running?
        uri = URI(URL)
        begin
          socket = TCPSocket.new uri.hostname, uri.port
          socket.close
          true
        rescue Errno::ECONNREFUSED
          false
        end
      end

      def wait_for_server
        # avoid retryable dependency
        tries = 0
        up = false
        uri = URI(URL)
        max_tries = 50
        while tries < max_tries && !up
          tries += 1
          sleep 0.1
          begin
            # Using TCPSocket, not net/http open because executing the HTTP GET / will incur a decent delay just to check if the server is up
            # in order to better communicate to the user what is going on, save the actual HTTP request for the phantom/node run
            # the only objective here is to see if the Rack server has started
            socket = TCPSocket.new uri.hostname, uri.port
            up = true
            socket.close
          rescue Errno::ECONNREFUSED
            # server not up yet
          end
        end
        raise "Tried #{max_tries} times to contact Rack server and not up!" unless up
      end

      def description
        'Execute opal::rspec tests'
      end
    end

    Spring.register_command 'orspec', Orspec.new
  end
end
