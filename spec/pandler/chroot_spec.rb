require "pathname"

describe Pandler::Chroot do
  before :all do
    @base_dir = File.expand_path("../../../.spec_cache", __FILE__)
    @chroot = Pandler::Chroot.new(:base_dir => @base_dir)
  end

  subject { @chroot }
  its(:root_dir) { should eq "#{@base_dir}/root" }
  its(:yumrepo)  { should eq "file://#{@base_dir}/yumrepo" }

  describe "chroot file path" do
    subject { @chroot.real_path("/") }
    it { should eq @chroot.root_dir + "/" }
  end

  describe "init" do
    before(:all) { @chroot.init }
    it "should create directories" do
      [
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
      ].each do |path|
        Pathname(@chroot.real_path(path)).should exist
      end
    end
    it "should create files" do
      [
        '/etc/mtab',
        '/etc/fstab',
        '/var/log/yum.log',
        '/etc/yum/yum.conf',
        '/etc/yum.conf',
        '/etc/resolv.conf',
        '/etc/hosts',
      ].each do |path|
        Pathname(@chroot.real_path(path)).should exist
      end
    end
    it "should create devs" do
      [
        '/dev/null',
        '/dev/full',
        '/dev/zero',
        '/dev/random',
        '/dev/urandom',
        '/dev/tty',
        '/dev/console',
        '/dev/stdin',
        '/dev/stdout',
        '/dev/stderr',
        '/dev/fd',
#        '/dev/ptmx',
      ].each do |path|
        Pathname(@chroot.real_path(path)).should exist
      end
    end
  end
end
