require 'tempfile'
require 'benchmark'
require 'retryable'

describe Spring::Commands::OpalRSpec do
  before :all do
    Dir.chdir 'test_app' do
      output = Bundler.with_clean_env do
        `bundle install`
      end
      raise output unless $?.success?
    end
  end

  # Spring seems goofy unless we use File I/O
  def run_stuff(command)
    file = Tempfile.new 'spring_test'
    file.close
    begin
      redir = "SPEC_OPTS='#{spec_opts}' #{command} 1> #{file.path} 2>&1"
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

  def dump_processes(desc)
    #puts "Processes #{desc}\n #{`ps ux`}"
  end

  def ensure_spring_shuts_down
    begin
      run_spring 'stop'
    rescue RuntimeError => e
      return e.message
    end
    Retryable.retryable(tries: 3, on: RSpec::Expectations::ExpectationNotMetError) do |tries, _|
      expect(`ps ux`).to_not match(/spring.*test_app/), "try #{tries}"
    end
  end

  before do
    dump_processes 'before, have not done anything'
    @benchmarks = []
    ensure_spring_shuts_down
    dump_processes 'before, after stop_spring_regardless'
  end

  after do
    dump_processes 'after, before doing anything'
    ensure_spring_shuts_down
    dump_processes 'after, after stop_spring_regardless'
  end

  let(:spec_opts) { '' }

  subject(:output) {
    output = nil
    @benchmarks << Benchmark.realtime do
      output = run_spring 'opal-rspec'
    end
    output
  }

  context 'spring not running' do
    it { is_expected.to match /1 example, 0 failures/ }
  end

  context 'spec_opts set' do
    let(:spec_opts) { '--format j' }

    it { is_expected.to match /\{"examples.*/ }
  end

  context 'spring already running' do
    before do
      # force the 1st task to run
      foo = output
      @benchmarks << Benchmark.realtime do
        @second_output = run_spring 'opal-rspec'
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
      run_spring 'opal-rspec'
    end

    subject { `ps ux` }

    context 'after 1 run' do
      it 'shuts down' do
        ensure_spring_shuts_down
      end
    end

    context 'after 2 runs' do
      before do
        run_spring 'opal-rspec'
      end

      it 'shuts down' do
        ensure_spring_shuts_down
      end
    end
  end

  context 'test fails' do
    before do
      @primary = File.join('config', 'application.rb')
      second = File.join('config', 'application_2.rb')
      @backup = "#{@primary}.backup"
      FileUtils.cp @primary, @backup
      FileUtils.cp second, @primary
    end

    after do
      FileUtils.mv @backup, @primary
    end

    subject { lambda { output } }

    it { is_expected.to raise_error /.*2 examples, 1 failure.*/ }
  end

  context 'opal spec location changed after run' do
    before do
      run_spring 'opal-rspec'
      @primary = File.join('config', 'application.rb')
      second = File.join('config', 'application_2.rb')
      @backup = "#{@primary}.backup"
      FileUtils.cp @primary, @backup
      FileUtils.cp second, @primary
      # give spring time to react
      sleep 2
    end

    after do
      FileUtils.mv @backup, @primary
    end

    subject { lambda { output } }

    it { is_expected.to raise_error /.*2 examples, 1 failure.*/ }
  end

  context 'test changed' do
    before do
      run_spring 'opal-rspec'
      @primary = File.join('spec', 'example_spec.rb')
      second = File.join('spec', 'swap.rb')
      @backup = "#{@primary}.backup"
      FileUtils.cp @primary, @backup
      FileUtils.cp second, @primary
    end

    after do
      FileUtils.mv @backup, @primary
    end

    it { is_expected.to match /2 examples, 0 failures/ }
  end
end
