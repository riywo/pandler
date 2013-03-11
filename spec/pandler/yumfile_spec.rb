describe Pandler::Yumfile do
  subject { Pandler::Yumfile.new }

  before do
    content = <<-EOF
repo "base",   "http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=os"
repo "update", "http://mirrorlist.centos.org/?release=6&arch=x86_64&repo=update"
    EOF
    write_yumfile content
    subject.load "Yumfile"
  end

  it "can load from a file" do
    should have(2).repos
    subject.repos.should have_key 'base'
    subject.repos.should have_key 'update'
  end
end
