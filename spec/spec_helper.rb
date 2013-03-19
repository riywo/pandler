require 'rspec'
require 'webmock/rspec'
require 'tmpdir'

require 'pandler'
require 'pandler/cli'

def pandle(args)
  capture_stdout do
    begin
      Pandler::CLI.start(args.split(" "))
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

module UserTempDir
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
#      FileUtils.remove_entry_secure @root_dir
      system "sudo rm -fr #{@root_dir}"
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
  config.include UserTempDir
end

