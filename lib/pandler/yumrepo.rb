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

    @cache_dir     = File.join(base_dir, "yumcache")
    @yum_log       = File.join(@cache_dir, "/var/lib/yum/pandler.log")
    FileUtils.mkdir_p base_dir
    FileUtils.mkdir_p repo_dir
    FileUtils.mkdir_p @cache_dir

    @yumfile   = Pandler::Yumfile.new(yumfile_path)
    @lockfile  = read_lockfile
  end

  def createrepo
    setup_dirs
    setup_files
    yum_download
    write_lockfile
    symlink_pkgs
    run_cmd("createrepo", "-v", repo_dir)
  end

  def install_pkgs
    specs.sort_by { |package, spec| spec["name"] }.map { |package, spec| package }
  end

  def specs
    @specs
  end

  private

  def run_cmd(*cmd)
    ret = Kernel.system(*cmd)
    raise "command failed(ret: #{ret}) '#{cmd.join(" ")}'" unless ret
  end

  def repos
    @yumfile.repos
  end

  def rpms
    @yumfile.rpms
  end

  def read_lockfile
    File.exists?(lockfile_path) ? YAML.load_file(lockfile_path) : nil
  end

  def write_lockfile
    open(@lockfile_path, "w") do |f|
      YAML.dump({
        "repos" => repos,
        "rpms"  => rpms,
        "specs" => specs,
      }, f)
    end
  end

  def download_pkgs #TODO
    pkgs = []
    if @lockfile.nil?
      pkgs = rpms
    else
      pkgs = @lockfile["specs"].keys
    end
    pkgs
  end

  def yum_download
    run_cmd(*yum("install", *download_pkgs))
    update_specs
  end

  def update_specs
    @specs = read_yum_log
    solve_comesfrom
  end

  def read_yum_log
    results = {}
    File.open(@yum_log).each_line do |log|
      data = Hash[log.chomp.split("\t").map{|f| f.split(":", 2)}]
      if results.has_key? data["package"]
        results[data["package"]]["relatedto"].push data["relatedto"]
      else
        package = data.delete("package")
        data["relatedto"] = [data["relatedto"]] if data.has_key?("relatedto")
        results[package] = data
      end
    end
    results
  end

  def solve_comesfrom
    @specs.each do |package, spec|
      next unless spec.has_key? "relatedto"

      checked_pkg = {}
      @specs[package]["comesfrom"] = comesfrom(package, checked_pkg)
    end
  end

  def comesfrom(pkgs, checked_pkg)
    rpm_list = []
    pkgs.each do |pkg|
      next if checked_pkg[pkg]

      checked_pkg[pkg] = true
      spec = @specs[pkg]
      if spec.has_key? "relatedto"
        spec["relatedto"].each do |related|
          rpm_list.push related unless rpms.index(@specs[related]["name"]).nil?
        end
        rpm_list += comesfrom(spec["relatedto"], checked_pkg)
      end
    end
    rpm_list.uniq
  end

  def yum(*args)
    cmd  = ["yum", "--disableplugin=*", "--enableplugin=pandler"]
    cmd += ["--installroot", @cache_dir, *args]
    cmd
  end

  def symlink_pkgs
    Dir.chdir(repo_dir) do
      pkgs = Dir.glob("../yumcache/var/cache/yum/**/packages/*.rpm")
      FileUtils.mkdir_p repo_dir
      FileUtils.ln_s(pkgs, ".", { :force => true })
    end
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
      '/etc/yum/plugin',
      '/etc/yum/pluginconf.d',
    ]
    dirs.each do |dir|
      FileUtils.mkdir_p(File.join(@cache_dir, dir))
    end
  end

  def setup_files
    open(File.join(@cache_dir, "/etc/yum/yum.conf"), "w") { |f| f.write yum_conf }
    open(File.join(@cache_dir, "/etc/yum/pluginconf.d/pandler.conf"), "w") { |f| f.write plugin_conf }
    FileUtils.cp(yum_plugin_path, File.join(@cache_dir, "/etc/yum/plugin"))
  end

  def yum_plugin_path
    File.expand_path("../../../etc/yum/pandler.py", __FILE__)
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
pluginpath=<%= @cache_dir %>/etc/yum/plugin
pluginconfpath=<%= @cache_dir %>/etc/yum/pluginconf.d
<% repos.each { |repo, url| %>
[<%= repo %>]
name=<%= repo %>
enabled=1
baseurl=<%= url %>
<% } %>
    EOF
    content.result(binding)
  end

  def plugin_conf
    content = <<-EOF
[main]
enabled=1
    EOF
    content
  end
end
