require "pandler"
require "thor"

class Pandler::CLI < Thor
  desc "version", "Display pandler version"
  map ["-v", "--version"] => :version
  def version
    puts Pandler::VERSION
  end

  desc "install", "Install"
  def install
    puts "pandle install"
  end
end
