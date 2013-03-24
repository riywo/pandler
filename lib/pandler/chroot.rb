require "etc"

class Pandler::Chroot
  attr_reader :base_dir, :root_dir, :yumrepo, :mounts

  def initialize(args = {})
    @base_dir = args[:base_dir] || File.expand_path("pandler")
    @root_dir = args[:root_dir] || File.join(base_dir, "root")
    @yumrepo  = args[:yumrepo]  || "file://" + File.join(base_dir, "yumrepo")

    @mounts = [
       { :type => 'proc',   :path => '/proc' },
       { :type => 'sysfs',  :path => '/sys' },
       { :type => 'tmpfs',  :path => '/dev/shm' },
       { :type => 'devpts', :path => '/dev/pts',
                            :options => "gid=#{Etc.getgrnam("tty").gid},mode=0620,ptmxmode=0666,newinstance" },
    ]
  end

  def real_path(path)
    File.join(root_dir, path)
  end

  def init
    setup_dirs
    setup_files
    setup_devs
    true
  end

  def yum(*cmd)
    yum_cmd = ["yum", "--installroot", root_dir] + cmd
    system(*yum_cmd)
  end

  private

  def write_file(path, content)
    open(real_path(path), "w") { |f| f.write content }
  end

  def mount_all
    @mounts.each do |entry|
      mount(entry)
    end
  end

  def mount(entry)
    cmd = ["mount", "-n", "-t", entry[:type]]
    cmd.concat ["-o", entry[:options]] if entry.has_key?(:options)
    cmd.concat ["pandler_mount_#{entry[:type]}", real_path(entry[:path])]
    system(*cmd)
  end

  def umount_all
    @mounts.each do |entry|
      umount(entry)
    end
  end

  def umount(entry)
    cmd = ["umount", "-n", "-l", real_path(entry[:path])]
    system(*cmd)
  end

  def setup_dirs
    FileUtils.mkdir_p root_dir
    dirs = [
      '/var/lib/rpm',
      '/var/lib/yum',
      '/var/lib/dbus',
      '/var/log',
      '/var/lock/rpm',
      '/var/cache/yum',
      '/etc/rpm',
      '/tmp',
      '/tmp/ccache',
      '/var/tmp',
      '/etc/yum.repos.d',
      '/etc/yum',
      '/proc',
      '/sys',
    ]
    dirs.each do |dir|
      FileUtils.mkdir_p real_path(dir)
    end
  end

  def setup_files
    files = [
      '/etc/mtab',
      '/etc/fstab',
      '/var/log/yum.log',
    ]
    files.each do |file|
      FileUtils.touch real_path(file)
    end

    write_file("/etc/yum/yum.conf", yum_conf)
    FileUtils.ln_s("yum/yum.conf", real_path("/etc/yum.conf"), { :force => true })
    FileUtils.cp("/etc/resolv.conf", real_path("/etc/resolv.conf"))
    FileUtils.cp("/etc/hosts", real_path("/etc/hosts"))
  end

  def setup_devs
    FileUtils.mkdir_p real_path("/dev/pts")
    FileUtils.mkdir_p real_path("/dev/shm")

    python_code = <<-PYTHON
import os, os.path, stat
devFiles = [
    (stat.S_IFCHR | 0666, os.makedev(1, 3), "#{real_path("/dev/null")}"),
    (stat.S_IFCHR | 0666, os.makedev(1, 7), "#{real_path("/dev/full")}"),
    (stat.S_IFCHR | 0666, os.makedev(1, 5), "#{real_path("/dev/zero")}"),
    (stat.S_IFCHR | 0666, os.makedev(1, 8), "#{real_path("/dev/random")}"),
    (stat.S_IFCHR | 0444, os.makedev(1, 9), "#{real_path("/dev/urandom")}"),
    (stat.S_IFCHR | 0666, os.makedev(5, 0), "#{real_path("/dev/tty")}"),
    (stat.S_IFCHR | 0600, os.makedev(5, 1), "#{real_path("/dev/console")}"),
#    (stat.S_IFCHR | 0666, os.makedev(5, 2), "#{real_path("/dev/ptmx")}"),
]
for i in devFiles:
    if os.path.exists(i[2]):
        continue
    else:
        os.mknod(i[2], i[0], i[1])
    PYTHON
    system("python", "-c", python_code)

    FileUtils.symlink("/proc/self/fd/0", real_path("/dev/stdin"), { :force => true })
    FileUtils.symlink("/proc/self/fd/1", real_path("/dev/stdout"), { :force => true })
    FileUtils.symlink("/proc/self/fd/2", real_path("/dev/stderr"), { :force => true })

    FileUtils.chown(Etc.getpwnam("root").uid, Etc.getgrnam("tty").gid, real_path("/dev/tty"))
#    FileUtils.chown(Etc.getpwnam("root").uid, Etc.getgrnam("tty").gid, real_path("/dev/ptmx"))

    unless File.exists? real_path("/dev/fd")
      FileUtils.symlink("/proc/self/fd", real_path("/dev/fd"), { :force => true })
    end
    FileUtils.symlink("pts/ptmx", real_path("/dev/ptmx"), { :force => true })
  end

  def yum_conf
    content = <<-EOF
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
plugins=0

[pandler]
name=Pandler
enabled=1
baseurl=#{yumrepo}
    EOF
    content
  end
end
