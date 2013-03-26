require "erb"

class Pandler::Yumrepo
  attr_reader :base_dir, :repo_dir, :yumfile_path, :tmp_dir
  def initialize(args)
    @base_dir     = args[:base_dir]     || File.expand_path("pandler")
    @repo_dir     = args[:repo_dir]     || File.join(base_dir, "yumrepo")
    @tmp_dir      = args[:tmp_dir]      || File.join(base_dir, "tmp")
    @yumfile_path = args[:yumfile_path] || File.expand_path("Yumfile")

    FileUtils.mkdir_p base_dir
    FileUtils.mkdir_p repo_dir
    @yumfile = Pandler::Yumfile.new(yumfile_path)
  end

  def yumfile
    @yumfile.load
  end

  def createrepo
    setup_dirs
    setup_files
    rpms = yumfile.rpms.keys
    yum_download(*rpms)
    system("createrepo", "-v", repo_dir)
    FileUtils.remove_entry_secure(tmp_dir)
  end

  def install_pkgs
    @install_pkgs
  end

  private

  def yum_download(*rpms)
    system("yum", "--disableplugin=*", "--enableplugin=downloadonly", "--installroot", tmp_dir, "--downloadonly", "install", *rpms)
    pkgs = Dir.glob("#{tmp_dir}/var/cache/yum/**/packages/*.rpm")
    @install_pkgs = pkgs.map { |path| File.basename(path, ".rpm") }
    FileUtils.mkdir_p repo_dir
    FileUtils.mv(pkgs, repo_dir)
  end

  def setup_dirs
    FileUtils.mkdir_p tmp_dir
    dirs = [
      '/var/lib/rpm',
      '/var/lib/yum',
      '/var/log',
      '/var/lock/rpm',
      '/var/cache/yum',
      '/tmp',
      '/var/tmp',
      '/etc/yum.repos.d',
      '/etc/yum',
    ]
    dirs.each do |dir|
      FileUtils.mkdir_p(File.join(tmp_dir, dir))
    end
  end

  def setup_files
    open(File.join(tmp_dir, "/etc/yum/yum.conf"), "w") { |f| f.write yum_conf }
  end

  def yum_conf
    content = ERB.new <<-EOF
[main]
cachedir=/var/cache/yum
debuglevel=1
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=0
assumeyes=1
syslog_ident=pandler
syslog_device=
plugins=1
<% yumfile.repos.each { |repo, url| %>
[<%= repo %>]
name=<%= repo  %>
enabled=1
baseurl=<%= url %>
<% } %>
    EOF
    content.result(binding)
  end
end
