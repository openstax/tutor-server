# A thread-safe configurable module
module Configurable

  class << self
    def included(base)
      base.extend self
    end

    def extended(base)
      Rails.application.config.after_initialize{ base._after_initialize }
    end
  end

  def new_configuration
    raise NotImplementedError, "You must implement the #new_configuration method"
  end

  def new_client
    raise NotImplementedError, "You must implement the #new_client method"
  end

  def configuration=(config)
    Thread.current[configuration_variable_name] = config
  end

  def configuration
    Thread.current[configuration_variable_name] ||= \
      @static_configuration.nil? ? new_configuration : @static_configuration.dup
  end

  def configure
    yield configuration
  end

  def client=(client)
    Thread.current[client_configuration_variable_name] = configuration.dup.freeze
    Thread.current[client_variable_name] = client
  end

  def client
    return @static_client if static_configuration?
    return Thread.current[client_variable_name] unless client_configuration_changed?

    self.client = new_client
  end

  def _after_initialize
    @static_configuration = configuration.freeze
    @static_client = new_client
    Thread.current[configuration_variable_name] = nil
  end

  protected

  def configuration_variable_name
    "#{name}_configuration".to_sym
  end

  def client_variable_name
    "#{name}_client".to_sym
  end

  def client_configuration_variable_name
    "#{name}_client_configuration".to_sym
  end

  def static_configuration?
    configuration == @static_configuration
  end

  def client_configuration_changed?
    configuration != Thread.current[client_configuration_variable_name]
  end

end
