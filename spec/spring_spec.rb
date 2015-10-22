require 'tempfile'
require 'benchmark'

describe Spring::Commands::Orspec do
  # Spring seems goofy unless we use File I/O
  def run_stuff(command)
    file = Tempfile.new 'spring_test'
    file.close
    begin
      redir = "#{command} 1> #{file.path} 2>&1"
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
    @benchmarks = []
    stop_spring_regardless
  end

  after do
    stop_spring_regardless
  end

  subject(:output) {
    output = nil
    @benchmarks << Benchmark.realtime do
      output = run_spring 'orspec'
    end
    output
  }

  context 'spring not running' do
    it { is_expected.to match /1 example, 0 failures/ }
  end

  context 'spring already running' do
    before do
      # force the 1st task to run
      foo = output
      @benchmarks << Benchmark.realtime do
        @second_output = run_spring 'orspec'
      end
    end

    subject { @second_output }

    it { is_expected.to match /1 example, 0 failures/ }
    it 'is faster the 2nd time' do
      expect(@benchmarks[1]).to be < @benchmarks[0]
    end
  end

  context 'spring stop' do
    before do
      run_spring 'orspec'
    end

    subject { `ps ux` }

    context 'after 1 run' do
      before do
        stop_spring_regardless
        sleep 1
      end

      it { is_expected.to_not match /spring.*test_app/ }
    end

    context 'after 2 runs' do
      before do
        run_spring 'orspec'
        stop_spring_regardless
        sleep 1
      end

      it { is_expected.to_not match /spring.*test_app/ }
    end
  end

  context 'opal spec location changed' do
    around do |ex|
      run_spring 'orspec'
      primary = File.join('config', 'application.rb')
      second = File.join('config', 'application_2.rb')
      backup = "#{primary}.backup"
      FileUtils.cp primary, backup
      FileUtils.cp second, primary
      ex.run
      FileUtils.mv backup, primary
    end

    subject { lambda { output } }

    it { is_expected.to raise_error /.*2 examples, 1 failure.*/ }
  end

  context 'test changed' do
    pending 'write this'
  end
end
