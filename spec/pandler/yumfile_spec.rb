describe Pandler::Yumfile do
  include TempDirHelper

  before :all do
    content = <<-EOF
repo "base",   "http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=os"
repo "update", "http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=update"

rpm "basesystem"
    EOF
    write_file("Yumfile", content)
    @yumfile = Pandler::Yumfile.new("Yumfile")
  end

  subject { @yumfile }
  it { should have(2).repos }
  its(:repos) { should have_key 'base' }
  its(:repos) { should have_key 'update' }
  its(:rpms)  { should have_key 'basesystem' }
end
