describe Pandler::Mock do
  before(:all) {
    repodir = File.expand_path("../../../spec/resources/repo", __FILE__)
    basedir = ENV["PANDLER_RSPEC_MOCK_CACHE"] == "1" ? "#{@old_pwd}/.spec_cache" : nil
    @mock = Pandler::Mock.new(:basedir => basedir, :repodir => repodir)
    @mock.init unless File.exists?("#{basedir}/#{@mock.root}")
  }

  subject { @mock }

  describe 'shell(echo "test")' do
    subject {
      stdin, stdout, stderr = @mock.shell('echo "test"')
      stdout.readlines.join('')
    }
    it { should eq "test\n" }
  end

  after(:all) {
    @mock.clean unless ENV["PANDLER_RSPEC_MOCK_CACHE"] == "1"
  }
end
