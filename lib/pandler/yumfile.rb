class Pandler::Yumfile
  attr_reader :repos, :rpms

  def initialize(filename)
    @repos = {}
    @rpms = []
    load_file(filename) if File.exists? filename
  end

  private

  def load_file(filename)
    contents = File.read(filename)
    instance_eval(contents, filename, 1)
    @rpms.sort!
    self
  end

  def repo(name, url)
    @repos[name] = url
  end

  def rpm(name)
    @rpms.push(name)
  end
end
