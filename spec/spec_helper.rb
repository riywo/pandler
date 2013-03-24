require 'rspec'
require 'webmock/rspec'
require 'tmpdir'
require 'open3'

require 'pandler'
require 'pandler/cli'

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

class Pandler::Chroot
  def chroot_run_cmd(*cmd)
    chroot_cmd = ["chroot", root_dir] + cmd
    Open3.popen3(*chroot_cmd) do |stdin, stdout, stderr|
      stdin.close_write
      $stdout.puts(stdout.read)
      $stderr.puts(stdout.read)
    end
  end
end

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
      basedir = "#{@old_pwd}/.spec_cache"
      @mock = Pandler::Mock.new(:basedir => basedir, :repodir => repodir)
      @mock.init if init?
    end
  end

  def init?
    return true unless File.exists?("#{@mock.basedir}/#{@mock.root}")

    if ENV["PANDLER_RSPEC_MOCK_INIT"] == "1"
      ENV.delete "PANDLER_RSPEC_MOCK_INIT"
      return true
    end

    return nil
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

