class Pandler::Yumfile
  attr_reader :repos, :rpms

  def initialize(filename)
    @repos = {}
    @rpms = {}
    @filename = filename
  end

  def load(contents = nil)
    contents ||= File.read(@filename)
    instance_eval(contents, @filename, 1)
    self
  end

  def repo(name, url)
    @repos[name] = url
  end

  def rpm(name)
    @rpms[name] = name
  end
end
