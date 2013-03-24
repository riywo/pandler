require "pandler"
require "thor"

class Pandler::CLI < Thor
  class_option :yumfile, :type => :string, :aliases => "-f", :desc => "Default: Yumfile"

  def initialize(args=[], options={}, config={})
    super
    @chroot = Pandler::Chroot.new
#    @yumrepo = config[:yumrepo] || Pandler::Yumrepo.new(:mock => @mock, :yumfile => options[:yumfile])
  end

  desc "version", "Display pandler version"
  map ["-v", "--version"] => :version
  def version
    puts Pandler::VERSION
  end

  desc "install", "Install"
  def install(*pkgs)
    @chroot.init
    @chroot.install(*pkgs)
#    @yumrepo.prepare_install
#
#    if @mock.not_init?
#      @mock.init(@yumrepo.locked_pkgs)
#    else
#      @mock.install(@yumrepo.install_pkgs)
#      @mock.remove(@yumrepo.remove_pkgs)
#    end
#
#    @yumrepo.save_lockfile
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
