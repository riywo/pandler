class Pandler::Yumfile
  attr_reader :repos

  def initialize(filename = nil)
    @repos = {}
    load(filename) if filename
  end

  def load(filename, contents = nil)
    contents ||= File.read(filename)
    instance_eval(contents, filename, 1)
  end

  def repo(name, url)
    @repos[name] = url
  end

end
