describe Pandler::CLI do
  subject { Pandler::CLI.new }

  describe "version" do
    it "displays gem version" do
      pandle("version").chomp.should == Pandler::VERSION
    end

    it "displays gem version on shortcut command" do
      pandle("-v").chomp.should == Pandler::VERSION
    end
  end
end
