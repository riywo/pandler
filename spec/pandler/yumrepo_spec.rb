require "pathname"
require "webrick"

describe Pandler::Yumrepo do
  include TempDirHelper
  before :all do
    @base_dir = File.expand_path("repo")
    test_port = 9999

    yumfile = <<-EOF
repo "test",   "http://localhost:#{test_port}"
rpm  "pandler-test"
rpm  "pandler-test-a"
rpm  "pandler-test-dep-a"
rpm  "pandler-test-dep-b"
    EOF
    write_file("Yumfile", yumfile)
    yumfile_lock = <<-EOF
repos:
  test: http://localhost:#{test_port}
specs:
  pandler-test-dep-a-0.0.1-1.x86_64:
    name: pandler-test-dep-a
    arch: x86_64
    version: 0.0.1
    release: "1"
  pandler-test-a-0.0.1-1.x86_64:
    name: pandler-test-a
    arch: x86_64
    version: 0.0.1
    release: "1"
  pandler-test-0.0.1-1.x86_64:
    name: pandler-test
    arch: x86_64
    version: 0.0.1
    release: "1"
  pandler-test-dep-b-0.0.1-1.x86_64:
    name: pandler-test-dep-b
    arch: x86_64
    version: 0.0.1
    release: "1"
  pandler-test-dep-required-0.0.1-1.x86_64:
    relatedto:
    - pandler-test-dep-a-0.0.1-1.x86_64
    - pandler-test-dep-b-0.0.1-1.x86_64
    name: pandler-test-dep-required
    arch: x86_64
    release: "1"
    version: 0.0.1
  pandler-test-dep-required-required-0.0.1-1.x86_64:
    version: 0.0.1
    relatedto:
    - pandler-test-dep-required-0.0.1-1.x86_64
    name: pandler-test-dep-required-required
    release: "1"
    arch: x86_64
rpms:
- pandler-test
- pandler-test-a
- pandler-test-dep-a
- pandler-test-dep-b
    EOF
    write_file("Yumfile.lock", yumfile_lock)
    @yumrepo = Pandler::Yumrepo.new(:base_dir => @base_dir)

    @server_thread = Thread.new do
      server = WEBrick::HTTPServer.new(
        :Port => test_port,
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

  subject { @yumrepo }
  its(:repo_dir) { should eq "#{@base_dir}/yumrepo" }
  its(:yumfile_path)  { should eq File.expand_path("Yumfile") }
  it("should have base_dir") { Pathname(@yumrepo.base_dir).should exist }
  it("should have repo_dir") { Pathname(@yumrepo.repo_dir).should exist }

  describe "createrepo" do
    before :all do
      @yumrepo.createrepo
    end
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
end
