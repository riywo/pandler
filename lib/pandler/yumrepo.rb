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
    FileUtils.mkdir_p cache_dir

    @solver = Pandler::Yumrepo::Solver.new(yumfile_path, lockfile_path, cache_dir)
  end

  def createrepo
    @solver.run
    symlink_pkgs
    system("createrepo", "-v", repo_dir)
  end

  def install_pkgs
    @solver.install_pkgs
  end

  def remove_pkgs
    @solver.remove_pkgs
  end

  private

  def symlink_pkgs
    Dir.chdir(repo_dir) do
      pkgs = Dir.glob("cache/var/cache/yum/**/packages/*.rpm")
      FileUtils.mkdir_p repo_dir
      FileUtils.ln_s(pkgs, ".", { :force => true })
    end
  end

  def cache_dir
    File.join(repo_dir, "cache")
  end

  class Solver
    attr_reader :install_pkgs, :remove_pkgs, :cache_dir
    def initialize(yumfile_path, lockfile_path, cache_dir)
      @yumfile_path = yumfile_path
      @lockfile_path = lockfile_path
      @cache_dir = cache_dir
      @yumfile   = Pandler::Yumfile.new(yumfile_path)
      @lockfile  = File.exists?(lockfile_path) ? YAML.load_file(lockfile_path) : {}
    end

    def run
      setup_dirs
      setup_files
      setup_pkgs
      write_lockfile
    end

    private

    def repos
      @yumfile.repos
    end

    def write_lockfile
      open(@lockfile_path, "w") do |f|
        YAML.dump({
          :repos => repos,
          :rpms  => @yumfile.rpms, #temp
          :specs => @zero_install_pkgs,
        }, f)
      end
    end

    def setup_pkgs
      @install_pkgs = zero_install_pkgs
      @remove_pkgs  = [] #temp
    end

    def zero_install_pkgs
      if @zero_install_pkgs.nil?
        @zero_install_pkgs = yum_download(spec_pkgs)
      end
      pkgs_to_s(@zero_install_pkgs)
    end

    def spec_pkgs
      # TODO consider deps for removing pkgs
      specs = @yumfile.rpms.merge(@lockfile[:specs]) do |name, yumfile_pkg, locked_pkg|
        if yumfile_pkg[:version].nil?
          locked_pkg
        else
          yumfile_pkg
        end
      end
      pkgs_to_s(specs)
    end

    def pkgs_to_s(pkgs)
      pkgs.sort_by { |name, v| name }.map do |name, spec|
        str  = name
        str += "-#{spec[:version]}" if spec.has_key? :version
        str += ".#{spec[:arch]}"    if spec.has_key? :arch
        str
      end
    end

    def yum
      cmd  = ["yum", "--disableplugin=*", "--enableplugin=downloadonly"]
      cmd += ["--installroot", cache_dir]
      cmd
    end

    def yum_download(pkgs)
      cmd = yum + ["--downloadonly", "install", *pkgs]

      install_pkgs = {}
      Open3.popen3(*cmd) do |stdin, stdout, stderr|
        stdin.close
        install_pkgs = parse_yum_download(stdout)
      end
      install_pkgs
    end

    def parse_yum_download(stdout)
      pkgs = {}
      stdout.read.each do |line|
        # parse yum install output
        data = line.split(nil, 5)
        next if data.size != 5
        next if ["Package", "Total", "Installed"].index data[0]
        name, arch, version = data
        version, epoch = version.split(":", 2).reverse

        pkgs[name] = { :version => version, :arch => arch }
        pkgs[name][:epoch] = epoch.to_i unless epoch.nil?
      end
      pkgs
    end

    def setup_dirs
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
end
