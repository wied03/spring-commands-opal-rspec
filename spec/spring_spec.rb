require 'tempfile'

describe Spring::Commands::Orspec do
  # Spring seems goofy unless we use File I/O
  def run_stuff(command)
    file = Tempfile.new 'spring_test'
    file.close
    begin
      redir = "#{command} 1> #{file.path} 2>&1"
      puts "Running #{redir}"
      success = Bundler.clean_system redir
      output = File.read(file.path)
      raise "'#{command}' failed with output\n#{output.strip}" unless success
      output
    ensure
      file.unlink
    end
  end

  def run_spring(command)
    run_stuff "bin/spring #{command}"
  end

  around do |ex|
    Dir.chdir 'test_app' do
      puts "Running example in #{Dir.pwd}"
      ex.run
    end
  end

  def stop_spring_regardless
    begin
      run_spring 'stop'
    rescue RuntimeError
      # don't care if not running
    end
  end

  before do
    stop_spring_regardless
  end

  after do
    stop_spring_regardless
  end

  context 'spring not running' do
    subject { run_spring 'orspec' }

    it { is_expected.to match /1 example, 0 failures/ }
  end

  context 'spring already running' do
    pending 'write this'
  end

  context 'spring stop' do
    context 'after 1 run' do
      pending 'write this'
    end

    context 'after 2 runs' do
      pending 'write this'
    end
  end

  context 'Rakefile/pattern changed' do
    pending 'write this'
  end

  context 'test changed' do
    pending 'write this'
  end
end
