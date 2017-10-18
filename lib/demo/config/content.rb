require 'hashie/mash'
require_relative 'yaml_file_parser'

# Reads in a YAML file containg configuration
class Demo::Config::Content
  extend Forwardable

  def initialize(config_file)
    @configuration = Hashie::Mash.load(config_file, parser: Demo::Config::YamlFileParser).dup
    validate_config
  end

  def self.config_dir_variable_name
    "#{name.demodulize}_config_dir"
  end

  def self.[](config)
    # The directory for the config files can be either set using either
    # config_directory block (which sets it's value using RequestStore.store),
    # the CONFIG environmental variable or the default
    config_dir = RequestStore.store[config_dir_variable_name.downcase] ||
                 ENV[config_dir_variable_name.upcase] ||
                 const_get('DEFAULT_CONFIG_DIR') rescue 'config/demo'

    config_string = config.to_s
    config_string = '' if config_string == 'all'

    all_filenames = Dir[File.join(config_dir, '**/*.yml')]
    filenames = all_filenames.select { |path| path.sub(config_dir, '').include?(config_string) }
    filenames.map { |file| self.new(file) }
  end

  def self.with_config_directory( directory )
    prev_config = RequestStore.store[:course_config_dir]
    RequestStore.store[:course_config_dir] = directory

    yield self
  ensure
    RequestStore.store[:course_config_dir] = prev_config
  end

  protected

  # Can be overriden in subclasses to implement YAML file validation
  def validate_config
  end
end
