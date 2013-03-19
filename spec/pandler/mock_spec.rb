describe Pandler::Mock do
  before {
    cache_topdir = File.expand_path("../../../.spec_cache", __FILE__)
    @mock = Pandler::Mock.new(:cache_topdir => cache_topdir)
  }

  subject { @mock }

  describe 'init' do
    subject { @mock.init }
    it { should be_true }
  end
end
