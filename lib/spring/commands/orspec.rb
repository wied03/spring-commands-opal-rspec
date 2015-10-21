require 'rack'
require 'webrick'
require 'spring/server'
require 'spring/client'
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
  module Commands
    # class Orspec
    #   def call
    #     puts 'ran command'
    #   end
    # end
    class Orspec
      def env(*)
        'test'
      end

      def call
        thread = start_server
        begin
          launch_phantom
        ensure
          thread.kill
        end
      end

      PORT = 9999
      URL = "http://localhost:#{PORT}/"

      def launch_phantom(timeout_value=nil)
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
        #system command_line
        pid = Process.spawn command_line
        Process.wait pid
        success = $?.success?
        exit 1 unless success
      end

      def start_server
        puts caller
        puts "our PID is #{Process.pid}, parent pid is #{Process.ppid}"
        pattern = ENV['PATTERN'] || (::Rails.application.config.opal.spec_location+'/**/*_spec{,.js}.{rb,opal}')
        sprockets_env = Opal::RSpec::SprocketsEnvironment.new(spec_pattern = pattern)
        app = Opal::Server.new(sprockets: sprockets_env) { |s|
          s.main = 'opal/rspec/sprockets_runner'
          s.debug = false

          ::Rails.application.assets.paths.each { |p| s.append_path p }
        }
        sprockets_env.add_spec_paths_to_sprockets
        locator1 = sprockets_env.instance_variable_get(:@locator)
        locator2 = Opal::RSpec::PostRackLocator.new(locator1)
        puts "spec files are #{locator2.get_opal_spec_requires}"
#        app_name = ::Spring::Env.new.app_name
#         server_pid = fork {
#           # Spring::ProcessTitleUpdater.run { |distance|
#           #   "spring app    | #{app_name} | started #{distance} ago | opal-rspec mode"
#           # }
#           Rack::Server.start(
#               :app => app,
#               :Port => PORT,
#               :AccessLog => [],
#               :Logger => WEBrick::Log.new("/dev/null"),
#           )
#         }
#         puts "server pid is #{server_pid}"
        thread = Thread.new do
          Thread.current.abort_on_exception = true
          Rack::Server.start(
              :app => app,
              :Port => PORT,
              :AccessLog => [],
              :Logger => WEBrick::Log.new("/dev/null"),
          )
        end
        wait_for_server
        thread
      end

      def wait_for_server
        # avoid retryable dependency
        tries = 0
        up = false
        uri = URI(URL)
        while tries < 4 && !up
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
        raise 'Tried 4 times to contact Rack server and not up!' unless up
      end

      def description
        'Execute opal::rspec tests'
      end
    end

    Spring.register_command 'orspec', Orspec.new
  end
end
