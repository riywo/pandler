describe Pandler::Mock do
  include MockHelper
  describe 'shell(echo "test")' do
    subject {
      stdin, stdout, stderr = @mock.shell('echo "test"')
      stdout.readlines.join('')
    }
    it { should eq "test\n" }
  end
end
