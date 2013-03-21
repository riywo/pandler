describe Pandler::CLI do
  include MockHelper
  include PandleHelper
  describe "version" do
    it "displays gem version" do
      pandle("version").chomp.should == Pandler::VERSION
    end

    it "displays gem version on shortcut command" do
      pandle("-v").chomp.should == Pandler::VERSION
    end
  end

  describe "exec echo 'test'" do
    subject { pandle("exec echo 'test'") }
#    it { should eq "test\n" }
  end
end
