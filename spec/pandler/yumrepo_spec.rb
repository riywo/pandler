require "pathname"

describe Pandler::Yumrepo do
  include TempDirHelper
  before :all do
    @base_dir = File.expand_path("repo")
    @yumrepo = Pandler::Yumrepo.new(:base_dir => @base_dir)

    yumfile = <<-EOF
repo "base",   "http://vault.centos.org/6.2/os/x86_64"
rpm "basesystem"
    EOF
    write_file("Yumfile", yumfile)
  end

  subject { @yumrepo }
  its(:repo_dir) { should eq "#{@base_dir}/yumrepo" }
  its(:yumfile_path)  { should eq File.expand_path("Yumfile") }
  it("should have base_dir") { Pathname(@yumrepo.base_dir).should exist }
  it("should have repo_dir") { Pathname(@yumrepo.repo_dir).should exist }

  describe "yumfile" do
    subject { @yumrepo.yumfile }
    its(:repos) { should have_key "base" }
    its(:rpms)  { should have_key "basesystem" }
  end

  describe "createrepo" do
    before :all do
      @yumrepo.createrepo
    end
#    it("should have repodata") { Pathname("#{@yumrepo.repo_dir}/repodata").should exist }
    it do
      system "tree repo"
    end
  end
end
