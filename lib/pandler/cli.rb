require "pandler"
require "thor"

class Pandler::CLI < Thor
  class_option :yumfile, :type => :string, :aliases => "-f", :desc => "Default: Yumfile"

  def initialize(args=[], options={}, config={})
    super
    @chroot = Pandler::Chroot.new
    @yumrepo = Pandler::Yumrepo.new
  end

  desc "version", "Display pandler version"
  map ["-v", "--version"] => :version
  def version
    puts Pandler::VERSION
  end

  desc "install", "Install"
  def install
    @chroot.init
    @yumrepo.createrepo
    @chroot.install(*@yumrepo.install_pkgs)
  end

  desc "list", "List"
  def list
    puts @chroot.list
  end

  desc "clean", "Clean"
  def clean
    @chroot.clean
  end

  desc "exec", "Execute"
  def exec(*cmd)
    @chroot.execute(*cmd)
  end
end
