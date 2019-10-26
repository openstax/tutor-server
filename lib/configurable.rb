require 'configurable/client_methods'

# Thread-safe configuration methods
# Can be configured in initializers
# Other threads will not see (shallow) changes to the configuration
# To persist changes, read the docs for #save_static_configuration! below
module Configurable

  class << self
    def included(base)
      base.extend self
    end

    def extended(base)
      Rails.application.config.after_initialize { base.save_static_configuration! }
    end
  end

  def new_configuration
    raise NotImplementedError, "You must implement the #new_configuration method"
  end

  def configuration=(config)
    RequestStore.store[configuration_variable_name] = config
  end

  def configuration
    RequestStore.store[configuration_variable_name] ||= \
      @static_configuration.nil? ? new_configuration : @static_configuration.dup
  end

  def configure
    yield configuration
  end

  # Note that this method affects the current process only
  # To propagate changes after initialization, check some condition on the database,
  # modify or assign the configuration and then call this method wherever the configuration is used
  # Make sure to wrap the check AND the call to #save_static_configuration!
  # in a Mutex or Monitor to prevent concurrent access
  def save_static_configuration!
    @static_configuration = configuration.freeze.tap { self.configuration = nil }
  end

  protected

  def configuration_variable_name
    "#{name}_configuration".to_sym
  end

  def static_configuration?
    configuration == @static_configuration
  end

end
