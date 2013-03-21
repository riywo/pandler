require "pandler"
require "thor"

class Pandler::CLI < Thor
  def self.start(given_args=ARGV, config={})
    super
  end

  desc "version", "Display pandler version"
  map ["-v", "--version"] => :version
  def version
    puts Pandler::VERSION
  end

  desc "install", "Install"
  def install
    puts "pandle install"
  end

  desc "exec", "Execute"
  def exec(*cmd)
    puts cmd
  end
end
