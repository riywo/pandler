require "pandler"
require "thor"

class Pandler::CLI < Thor
  def initialize(args=[], options={}, config={})
    super
    @mock = config[:mock]
  end

  desc "version", "Display pandler version"
  map ["-v", "--version"] => :version
  def version
    puts Pandler::VERSION
  end

  desc "install", "Install"
  def install
    @mock.init
  end

  desc "exec", "Execute"
  def exec(*cmd)
    stdin, stdout, stderr = @mock.shell(cmd.join(" "))
    puts stdout.readlines.join('')
  end
end
