describe Pandler::Mock do
  before(:all) {
    repodir      = File.expand_path("../../../spec/resources/repo", __FILE__)
    @mock = Pandler::Mock.new(:repodir => repodir)
  }

  subject { @mock }

  describe 'init' do
    subject { @mock.init }
    it { should be_true }
  end

  after(:all) {
    @mock.clean
  }
end
