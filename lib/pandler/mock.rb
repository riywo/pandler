class Pandler::Mock
  attr_reader :basedir, :cache_topdir, :configdir, :resultdir, :root, :mock_cmd

  def initialize(args = {})
    @basedir      = args[:basedir]      || File.expand_path("pandler")
    @cache_topdir = args[:cache_topdir] || "#{@basedir}/cache"
    @configdir    = args[:configdir]    || "#{@basedir}/conf"
    @resultdir    = args[:resultdir]    || "#{@basedir}/log"
    @root         = args[:root]         || "mock"
    @mock_cmd     = args[:mock_cmd]     || "mock"
    init_cfg
  end

  def init
    system "#{mock_cmd} --configdir #{configdir} --root #{root} --resultdir #{resultdir} --init"
  end

  def clean
    system "#{mock_cmd} --configdir #{configdir} --root #{root} --resultdir #{resultdir} --clean"
  end

  private

  def init_cfg
    Dir.mkdir basedir   unless File.exists? basedir
    Dir.mkdir configdir unless File.exists? configdir
    Dir.mkdir resultdir unless File.exists? resultdir

    open("#{configdir}/#{root}.cfg", 'w') do |f|
      f.write <<-"EOF"
config_opts['basedir'] = '#{basedir}'
config_opts['cache_topdir'] = '#{cache_topdir}'
config_opts['plugin_conf']['root_cache_enable'] = False

config_opts['root'] = '#{root}'
config_opts['target_arch'] = 'x86_64'
config_opts['legal_host_arches'] = ('x86_64',)
config_opts['chroot_setup_cmd'] = 'install rpm shadow-utils'
config_opts['dist'] = 'el6'  # only useful for --resultdir variable subst

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
[base]
name=BaseOS
enabled=1
mirrorlist=http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=os
failovermethod=priority

[updates]
name=updates
enabled=1
mirrorlist=http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=updates
failovermethod=priority

[epel]
name=epel
mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=x86_64
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
