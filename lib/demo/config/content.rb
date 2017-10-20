require 'hashie/mash'
require_relative 'yaml_file_parser'

# Reads in a YAML file containg configuration
class Demo::Config::Content
  extend Forwardable

  def initialize(config_file)
    @configuration = Hashie::Mash.load(config_file, parser: Demo::Config::YamlFileParser).dup
    validate_config
  end

  def self.config_dir
    raise NotImplementedError
  end

  def self.[](config)
    config_string = config.to_s
    config_string = '' if config_string == 'all'

    all_filenames = Dir[File.join(config_dir, '**/*.yml')]
    filenames = all_filenames.select { |path| path.sub(config_dir, '').include?(config_string) }
    filenames.map { |file| new(file) }
  end

  protected

  # Can be overriden in subclasses to implement YAML file validation
  def validate_config
  end
end
