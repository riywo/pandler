require "pathname"
require "webrick"

describe Pandler::Yumrepo do
  include TempDirHelper
  before :all do
    @base_dir = File.expand_path("repo")
    @yumrepo = Pandler::Yumrepo.new(:base_dir => @base_dir)
    test_port = 9999

    yumfile = <<-EOF
repo "test",   "http://localhost:#{test_port}"
rpm  "pandler-test"
    EOF
    write_file("Yumfile", yumfile)

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

  describe "yumfile" do
    subject { @yumrepo.yumfile }
    its(:repos) { should have_key "test" }
    its(:rpms)  { should have_key "pandler-test" }
  end

  describe "createrepo" do
    before :all do
      @yumrepo.createrepo
    end
    it("should have repodata") { Pathname("#{@yumrepo.repo_dir}/repodata").should exist }
    it("should have pandle-test") { Pathname("#{@yumrepo.repo_dir}/pandler-test-0.0.1-1.x86_64.rpm").should exist }
    its(:install_pkgs) { should eq ["pandler-test-0.0.1-1.x86_64"] }
  end
end
