require "open3"

class Pandler::Mock
  attr_reader :basedir, :cache_topdir, :configdir, :resultdir, :repodir, :root, :mock_cmd, :init_pkgs

  def initialize(args = {})
    @basedir      = args[:basedir]      || File.expand_path("pandler")
    @cache_topdir = args[:cache_topdir] || "#{@basedir}/cache"
    @configdir    = args[:configdir]    || "#{@basedir}/conf"
    @resultdir    = args[:resultdir]    || "#{@basedir}/log"
    @repodir      = args[:repodir]      || "#{@basedir}/repo"
    @root         = args[:root]         || "mock"
    @mock_cmd     = args[:mock_cmd]     || "mock"
    @init_pkgs    = args[:init_pkgs]    || ["rpm", "shadow-utils"]
  end

  def init(*pkgs)
    @init_pkgs = pkgs if pkgs.size != 0
    mock("--init")
  end

  def install(*pkgs)
    mock("--install", *pkgs)
  end

  def remove(*pkgs)
    mock("--remove", *pkgs)
  end

  def shell(cmd)
    mock("-q", "--shell", cmd)
  end

  def scrub(type)
    mock("--scrub", type)
  end

  def clean
    mock("--clean")
  end

  private

  def mock(*args)
    init_cfg
    args.concat(opts)
    system(mock_cmd, *args)
  end

  def opts
    return "--no-cleanup-after", "--configdir", configdir, "--root", root, "--resultdir", resultdir
  end

  def init_cfg
    Dir.mkdir basedir      unless File.exists? basedir
    Dir.mkdir configdir    unless File.exists? configdir
    Dir.mkdir resultdir    unless File.exists? resultdir
    Dir.mkdir cache_topdir unless File.exists? cache_topdir

    open("#{configdir}/#{root}.cfg", 'w') do |f|
      f.write <<-"EOF"
config_opts['basedir'] = '#{basedir}'
config_opts['cache_topdir'] = '#{cache_topdir}'
config_opts['root'] = '#{root}'
config_opts['target_arch'] = 'x86_64'
config_opts['legal_host_arches'] = ('x86_64',)
config_opts['chroot_setup_cmd'] = 'install #{init_pkgs.join(" ")}'
config_opts['dist'] = 'el6'  # only useful for --resultdir variable subst

config_opts['plugin_conf']['ccache_enable'] = False
config_opts['plugin_conf']['yum_cache_enable'] = False
config_opts['plugin_conf']['root_cache_enable'] = False

config_opts['yum.conf'] = """
[main]
cachedir=/var/cache/yum
debuglevel=1
reposdir=/dev/null
logfile=/var/log/yum.log
retries=20
obsoletes=1
gpgcheck=0
assumeyes=1
syslog_ident=mock
syslog_device=

# repos
[pandler]
name=Pandler
enabled=1
baseurl=file://#{repodir}
failovermethod=priority
"""
      EOF
    end

    open("#{configdir}/site-defaults.cfg", 'w') do |f|
    end

    open("#{configdir}/logging.ini", 'w') do |f|
      f.write <<-EOF
[formatters]
keys: detailed,simple,unadorned,state

[handlers]
keys: simple_console,detailed_console,unadorned_console,simple_console_warnings_only

[loggers]
keys: root,build,state,mockbuild

[formatter_state]
format: %(asctime)s - %(message)s

[formatter_unadorned]
format: %(message)s

[formatter_simple]
format: %(levelname)s: %(message)s

;useful for debugging:
[formatter_detailed]
format: %(levelname)s %(filename)s:%(lineno)d:  %(message)s

[handler_unadorned_console]
class: StreamHandler
args: []
formatter: unadorned
level: INFO

[handler_simple_console]
class: StreamHandler
args: []
formatter: simple
level: INFO

[handler_simple_console_warnings_only]
class: StreamHandler
args: []
formatter: simple
level: WARNING

[handler_detailed_console]
class: StreamHandler
args: []
formatter: detailed
level: WARNING

; usually dont want to set a level for loggers
; this way all handlers get all messages, and messages can be filtered
; at the handler level
;
; all these loggers default to a console output handler
;
[logger_root]
level: NOTSET
handlers: simple_console

; mockbuild logger normally has no output
;  catches stuff like mockbuild.trace_decorator and mockbuild.util
;  dont normally want to propagate to root logger, either
[logger_mockbuild]
level: NOTSET
handlers:
qualname: mockbuild
propagate: 1

[logger_state]
level: NOTSET
; unadorned_console only outputs INFO or above
handlers: unadorned_console
qualname: mockbuild.Root.state
propagate: 0

[logger_build]
level: NOTSET
handlers: simple_console_warnings_only
qualname: mockbuild.Root.build
propagate: 0

; the following is a list mock logger qualnames used within the code:
;
;  qualname: mockbuild.util
;  qualname: mockbuild.uid
;  qualname: mockbuild.trace_decorator

      EOF
    end
  end
end
