require "erb"
require "open3"
require "yaml"

class Pandler::Yumrepo
  attr_reader :base_dir, :repo_dir, :yumfile_path, :lockfile_path
  def initialize(args = {})
    @base_dir      = args[:base_dir]      || File.expand_path("pandler")
    @repo_dir      = args[:repo_dir]      || File.join(base_dir, "yumrepo")
    @yumfile_path  = args[:yumfile_path]  || File.expand_path("Yumfile")
    @lockfile_path = args[:lockfile_path] || yumfile_path + ".lock"

    FileUtils.mkdir_p base_dir
    FileUtils.mkdir_p repo_dir
    @yumfile = Pandler::Yumfile.new(yumfile_path)
  end

  def save_lockfile
    open(lockfile_path, "w") do |f|
      YAML.dump({
        "repos" => repos,
        "rpms"  => rpms.keys,
        "specs" => @specs,
      }, f)
    end
  end

  def createrepo
    setup_dirs
    setup_files
    yum_download(rpms.keys)
    system("createrepo", "-v", repo_dir)
  end

  def install_pkgs
    @specs.map { |name, spec| "#{name}-#{spec[:version]}.#{spec[:arch]}" }
  end

  def repos
    @yumfile.repos
  end

  def rpms
    @yumfile.rpms
  end

  private

  def cache_dir
    File.join(repo_dir, "cache")
  end

  def yum_cmd(rpms)
    ["yum", "--disableplugin=*", "--enableplugin=downloadonly", "--installroot", cache_dir, "--downloadonly", "install", *rpms]
  end

  def yum_download(rpms)
    @specs = {}
    Open3.popen3(*yum_cmd(rpms)) do |stdin, stdout, stderr|
      stdin.close
      stdout.read.each do |line|
        # parse yum install output
        data = line.split(nil, 5)
        next if data.size != 5
        next if ["Package", "Total", "Installed"].index data[0]
        name, arch, version = data
        version, epoch = version.split(":", 2).reverse
        @specs[name] = { :version => version, :arch => arch }
        @specs[name][:epoch] = epoch.to_i unless epoch.nil?
      end
    end
    Dir.chdir(repo_dir) do
      pkgs = Dir.glob("cache/var/cache/yum/**/packages/*.rpm")
      FileUtils.mkdir_p repo_dir
      FileUtils.ln_s(pkgs, ".", { :force => true })
    end
    save_lockfile
  end

  def setup_dirs
    FileUtils.mkdir_p cache_dir
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
      FileUtils.mkdir_p(File.join(cache_dir, dir))
    end
  end

  def setup_files
    open(File.join(cache_dir, "/etc/yum/yum.conf"), "w") { |f| f.write yum_conf }
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
<% repos.each { |repo, url| %>
[<%= repo %>]
name=<%= repo  %>
enabled=1
baseurl=<%= url %>
<% } %>
    EOF
    content.result(binding)
  end
end
