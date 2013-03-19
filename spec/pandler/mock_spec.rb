describe Pandler::Mock do
  before { @mock = Pandler::Mock.new }
  subject { @mock }
  its(:configdir) { should eq "./pandler/conf" }
  its(:root) { should eq "pandler" }

  describe 'init' do
    subject { @mock.init }
    it { should be_true }
  end
end
