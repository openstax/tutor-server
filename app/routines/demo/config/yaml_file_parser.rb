class Demo::Config::YamlFileParser
  def initialize(file_path)
    @content = File.read(file_path)
    @helpers = Demo::Config::ContentHelper.new
    @file_path = file_path
  end

  def perform
    template = ERB.new(@content)
    template.filename = @file_path
    YAML.load template.result(@helpers.get_binding)
  end

  def self.perform(file_path)
    new(file_path).perform
  end
end
