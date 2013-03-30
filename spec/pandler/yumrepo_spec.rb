require "pathname"
require "webrick"


describe Pandler::Yumrepo do
  include TempDirHelper
  before :all do
    @base_dir = File.expand_path("repo")
    @test_port = 9999
    @server_thread = Thread.new do
      server = WEBrick::HTTPServer.new(
        :Port => @test_port,
        :Logger => WEBrick::Log.new('/dev/null'),
        :AccessLog => [],
        :StartCallback => Proc.new { Thread.main.wakeup },
        :DocumentRoot => File.expand_path("../../resources/yumrepo", __FILE__)
      )
      Signal.trap(:INT) { server.shutdown }
      server.start
    end
    Thread.stop
  end

  after :all do
    Process.kill(:INT, Process.pid)
    @server_thread.join
  end

  describe "createrepo" do
    before :all do
      yumfile = <<-EOF
repo "test",   "http://localhost:#{@test_port}"
rpm  "pandler-test"
rpm  "pandler-test-dep-a"
rpm  "pandler-test-dep-b"
rpm  "pandler-test-a"
      EOF
      write_file("Yumfile", yumfile)
      yumfile_lock = <<-EOF
repos:
  test: http://localhost:#{@test_port}
rpms:
- pandler-test-a
specs:
  pandler-test-a-0.0.1-1.x86_64:
    arch: x86_64
    comesfrom:
    - pandler-test-a-0.0.1-1.x86_64
    name: pandler-test-a
    release: "1"
    version: 0.0.1
      EOF
      write_file("Yumfile.lock", yumfile_lock)
      @yumrepo = Pandler::Yumrepo.new(:base_dir => @base_dir)
      @yumrepo.createrepo
    end
    subject { @yumrepo }
    its(:repo_dir) { should eq "#{@base_dir}/yumrepo" }
    its(:yumfile_path)  { should eq File.expand_path("Yumfile") }
    it("should have base_dir") { Pathname(@yumrepo.base_dir).should exist }
    it("should have repo_dir") { Pathname(@yumrepo.repo_dir).should exist }

    it("should have repodata") { Pathname("#{@yumrepo.repo_dir}/repodata").should exist }
    it("should have pandle-test") { Pathname("#{@yumrepo.repo_dir}/pandler-test-0.0.1-1.x86_64.rpm").should exist }
    its(:install_pkgs) { should eq [
       "pandler-test-0.0.1-1.x86_64",
       "pandler-test-a-0.0.1-1.x86_64",
       "pandler-test-dep-a-0.0.1-1.x86_64",
       "pandler-test-dep-b-0.0.1-1.x86_64",
       "pandler-test-dep-required-0.0.1-1.x86_64",
       "pandler-test-dep-required-required-0.0.1-1.x86_64",
    ] }
    it "should come from Yumfile rpms" do
      subject.specs["pandler-test-dep-a-0.0.1-1.x86_64"]["comesfrom"].should eq [
       "pandler-test-dep-a-0.0.1-1.x86_64",
      ]
      subject.specs["pandler-test-dep-required-0.0.1-1.x86_64"]["comesfrom"].should eq [
       "pandler-test-dep-a-0.0.1-1.x86_64",
       "pandler-test-dep-b-0.0.1-1.x86_64",
      ]
      subject.specs["pandler-test-dep-required-required-0.0.1-1.x86_64"]["comesfrom"].should eq [
       "pandler-test-dep-a-0.0.1-1.x86_64",
       "pandler-test-dep-b-0.0.1-1.x86_64",
      ]
    end
    it { system "cat Yumfile.lock" }
  end

  describe "rm pandler-test-dep-a" do
    before :all do
      yumfile = <<-EOF
repo "test",   "http://localhost:#{@test_port}"
rpm  "pandler-test"
rpm  "pandler-test-dep-b"
rpm  "pandler-test-a"
      EOF
      write_file("Yumfile", yumfile)
      @yumrepo = Pandler::Yumrepo.new(:base_dir => @base_dir)
      @yumrepo.createrepo
    end
    subject { @yumrepo }

    its(:install_pkgs) { should eq [
       "pandler-test-0.0.1-1.x86_64",
       "pandler-test-a-0.0.1-1.x86_64",
       "pandler-test-dep-b-0.0.1-1.x86_64",
       "pandler-test-dep-required-0.0.1-1.x86_64",
       "pandler-test-dep-required-required-0.0.1-1.x86_64",
    ] }
  end

  describe "rm pandler-test-dep-b" do
    before :all do
      yumfile = <<-EOF
repo "test",   "http://localhost:#{@test_port}"
rpm  "pandler-test"
rpm  "pandler-test-a"
      EOF
      write_file("Yumfile", yumfile)
      @yumrepo = Pandler::Yumrepo.new(:base_dir => @base_dir)
      @yumrepo.createrepo
    end
    subject { @yumrepo }

    its(:install_pkgs) { should eq [
       "pandler-test-0.0.1-1.x86_64",
       "pandler-test-a-0.0.1-1.x86_64",
    ] }
  end

  describe "add pandler-test-dep-a" do
    before :all do
      yumfile = <<-EOF
repo "test",   "http://localhost:#{@test_port}"
rpm  "pandler-test"
rpm  "pandler-test-dep-a"
rpm  "pandler-test-a"
      EOF
      write_file("Yumfile", yumfile)
      @yumrepo = Pandler::Yumrepo.new(:base_dir => @base_dir)
      @yumrepo.createrepo
    end
    subject { @yumrepo }

    its(:install_pkgs) { should eq [
       "pandler-test-0.0.1-1.x86_64",
       "pandler-test-a-0.0.1-1.x86_64",
       "pandler-test-dep-a-0.0.1-1.x86_64",
       "pandler-test-dep-required-0.0.1-1.x86_64",
       "pandler-test-dep-required-required-0.0.1-1.x86_64",
    ] }
  end
end
