require 'spring/commands'
require 'opal/rspec/rake_task'
require 'spring/application_opal'

module Spring
  module Commands
    class OpalRSpec
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
        rspec_path = Gem.loaded_specs['opal-rspec'].full_gem_path
        runner_path = File.join(rspec_path, 'vendor/spec_runner.js')

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
        Process.spawn({
                          'RAILS_ROOT' => ::Rails.root.to_s,
                          'RAILS_ENV' => 'test'
                      },
                      'ruby',
                      '-I',
                      File.expand_path('../..', __FILE__),
                      '-e',
                      'require "spring/commands/opal_rack_boot"')
      end

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
        max_tries = 50
        while tries < max_tries && !up
          tries += 1
          sleep 0.1
          up = server_running?
        end
        raise "Tried #{max_tries} times to contact Rack server and not up!" unless up
      end

      def description
        'Execute opal::rspec tests'
      end
    end

    Spring.register_command 'opal-rspec', OpalRSpec.new
  end
end
