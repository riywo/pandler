class Pandler::Yumfile
  attr_reader :repos, :rpms

  def initialize(filename)
    @repos = {}
    @rpms = {}
    @filename = filename
    @loaded = false
  end

  def repos
    load_file
    @repos
  end

  def rpms
    load_file
    @rpms
  end

  private

  def load_file
    self if @loaded
    contents = File.read(@filename)
    instance_eval(contents, @filename, 1)
    @loaded = true
    self
  end

  def repo(name, url)
    @repos[name] = url
  end

  def rpm(name)
    @rpms[name] = name
  end

end
