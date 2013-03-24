describe Pandler::Yumrepo do
  include TempDirHelper
  before :all do
    @base_dir = File.expand_path("repo")
    @yumrepo = Pandler::Yumrepo.new(:base_dir => @base_dir)
  end

  subject { @yumrepo }
  its(:repo_dir) { should eq "#{@base_dir}/yumrepo" }

end
