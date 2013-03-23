describe Pandler::Mock do
  include TempDirHelper
  include MockHelper
  describe 'shell(echo "test")' do
    subject {
      capture_stdout { @mock.shell('echo "test"') }
    }
    it { should eq "test\n" }
  end
end
