require 'spring/application'
require 'spring/commands'
require 'opal/rspec/rake_task'

# module Opal
#   module RSpec
#     class ApplicationManager < ::Spring::ApplicationManager
#       def initialize(app_env)
#         super
#         @app_env = 'opal_rspec'
#       end
#
#       def start_child(preload = false)
#         sprockets_env = Opal::RSpec::SprocketsEnvironment.new
#         app = Opal::Server.new(sprockets: sprockets_env) { |s|
#           s.main = 'opal/rspec/sprockets_runner'
#           s.debug = false
#
#           sprockets_env.spec_pattern = ENV['PATTERN'] || (::Rails.application.config.opal.spec_location+'/**/*_spec{,.js}.{rb,opal}')
#           ::Rails.application.assets.paths.each { |p| s.append_path p }
#           sprockets_env.add_spec_paths_to_sprockets
#         }
#         @pid = fork {
#           Rack::Server.start(
#               :app => app,
#               :Port => PORT,
#               :AccessLog => [],
#               :Logger => WEBrick::Log.new("/dev/null"),
#           )
#         }
#         puts "server pid is #{@pid}"
#         wait_for_server
#       end
#
#       def wait_for_server
#         # avoid retryable dependency
#         tries = 0
#         up = false
#         uri = URI(URL)
#         while tries < 4 && !up
#           tries += 1
#           sleep 0.1
#           begin
#             # Using TCPSocket, not net/http open because executing the HTTP GET / will incur a decent delay just to check if the server is up
#             # in order to better communicate to the user what is going on, save the actual HTTP request for the phantom/node run
#             # the only objective here is to see if the Rack server has started
#             socket = TCPSocket.new uri.hostname, uri.port
#             up = true
#             socket.close
#           rescue Errno::ECONNREFUSED
#             # server not up yet
#           end
#         end
#         raise 'Tried 4 times to contact Rack server and not up!' unless up
#       end
#     end
#
#     class Server < ::Spring::Server
#       def initialize(env = ::Spring::Env.new)
#         super
#         @applications = Hash.new { |h, k| h[k] = Opal::RSpec::ApplicationManager.new(k) }
#       end
#     end
#
#     class Client < Spring::Client::Run
#       def boot_server
#         env.socket_path.unlink if env.socket_path.exist?
#
#         pid = Process.spawn(
#             gem_env,
#             "ruby",
#             "-e", "gem 'spring', '#{Spring::VERSION}'; require 'spring-commands-orspec'; Opal::RSpec::Server.boot"
#         )
#
#         until env.socket_path.exist?
#           _, status = Process.waitpid2(pid, Process::WNOHANG)
#           exit status.exitstatus if status
#           sleep 0.1
#         end
#       end
#     end
#   end
# end

module Spring
  class Application
    def setup(command_wrapper)
      setup = if command_wrapper.command.is_a?(Spring::Commands::Orspec)
                pid = command_wrapper.command.setup
                puts "spring app, got pid #{pid} back"
                @opal_rspec_pid = pid
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
