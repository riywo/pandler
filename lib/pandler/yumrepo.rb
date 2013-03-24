class Pandler::Yumrepo
  attr_reader :base_dir, :repo_dir
  def initialize(args)
    @base_dir = args[:base_dir] || File.expand_path("pandler")
    @repo_dir = args[:repo_dir] || File.join(base_dir, "yumrepo")
  end
end
