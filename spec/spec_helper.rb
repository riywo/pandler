require 'rspec'
require 'webmock/rspec'
require 'tmpdir'

require 'pandler'
require 'pandler/cli'

module PandleHelper
  def self.included(example_group)
    example_group.extend self
  end

  def pandle(args)
    capture_stdout do
      begin
        Pandler::CLI.start(args.split(" "), { :mock => @mock })
      rescue SystemExit
      end
    end
  end

  def capture_stdout
    old_stdout = $stdout.dup
    rd, wr = IO.method(:pipe).arity.zero? ? IO.pipe : IO.pipe("BINARY")
    $stdout = wr
    yield
    wr.close
    rd.read
  ensure
    $stdout = old_stdout
  end
end

module MockHelper
  def self.extended(example_group)
    example_group.use_mock(example_group)
  end

  def self.included(example_group)
    example_group.extend self
  end

  def use_mock(describe_block)
    describe_block.before :all do
      repodir = "#{@old_pwd}/spec/resources/repo"
      basedir = ENV["PANDLER_RSPEC_MOCK_CACHE"] == "1" ? "#{@old_pwd}/.spec_cache" : nil
      @mock = Pandler::Mock.new(:basedir => basedir, :repodir => repodir)
      @mock.init unless File.exists?("#{basedir}/#{@mock.root}")
    end

    describe_block.after :all do
      @mock.clean unless ENV["PANDLER_RSPEC_MOCK_CACHE"] == "1"
    end
  end
end

module TempDirHelper
  def self.extended(example_group)
    example_group.use_tempdir(example_group)
  end

  def self.included(example_group)
    example_group.extend self
  end

  def use_tempdir(describe_block)
    describe_block.before :all do
      @old_pwd = Dir.pwd
      @root_dir = Dir.mktmpdir
      Dir.chdir @root_dir
    end

    describe_block.after :all do
      FileUtils.remove_entry_secure @root_dir
      Dir.chdir @old_pwd
    end
  end

  def mkdir(dirpath)
    path = "#{@root_dir}/#{dirpath}"
    Dir.mkdir path unless File.exists? path
    path
  end

  def write_file(filepath, content)
    path = "#{@root_dir}/#{filepath}"
    open(path, "w") do |f|
      f.puts content
    end
    path
  end
end

RSpec.configure do |config|
  config.include TempDirHelper
end

