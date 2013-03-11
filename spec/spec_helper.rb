require 'rspec'
require 'webmock/rspec'
require "fakefs"
require "fakefs/spec_helpers"

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

def write_yumfile(content)
  yumfile = "Yumfile"
  File.open(yumfile, "w") do |f|
    f.write content
  end

  File.expand_path(yumfile)
end
