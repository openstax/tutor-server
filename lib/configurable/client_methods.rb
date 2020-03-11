require 'configurable/client_error'

# Thread-safe configurable client methods
# Can be configured in initializers
# Other threads will not see (shallow) changes to the client
# To persist changes, read the docs for #save_static_client! below
module Configurable
  module ClientMethods
    class << self
      def included(base)
        base.extend self
      end

      def extended(base)
        Rails.application.config.after_initialize { base.save_static_client! }
      end
    end

    def client=(client)
      RequestStore.store[client_configuration_variable_name] = configuration.dup.freeze
      RequestStore.store[client_variable_name] = client
    end

    def client
      return RequestStore.store[client_variable_name] \
        unless RequestStore.store[client_variable_name].nil? || client_configuration_changed?

      self.client = static_client? ? @static_client.dup : new_client
    end

    def new_client
      configuration.stub ? new_fake_client : new_real_client
    rescue StandardError => error
      raise OpenStax::Configurable::ClientError.new('initialization failure', error)
    end

    def use_fake_client(&block)
      previous_client = client

      begin
        self.client = new_fake_client
        block.call unless block.nil?
      ensure
        self.client = previous_client unless block.nil?
      end
    end

    def use_real_client(&block)
      previous_client = client

      begin
        self.client = new_real_client
        block.call unless block.nil?
      ensure
        self.client = previous_client unless block.nil?
      end
    end

    def new_fake_client
      raise NotImplementedError, 'You must implement the #new_fake_client method'
    end

    def new_real_client
      raise NotImplementedError, 'You must implement the #new_real_client method'
    end

    # Note that this method affects the current process only
    # To propagate changes after initialization, check some condition on the database,
    # modify or assign the configuration and then call this method wherever the client is used
    # Make sure to wrap the check AND the call to #save_static_client!
    # in a Mutex or Monitor to prevent concurrent access
    def save_static_client!
      @static_client = client.freeze.tap { self.client = nil }
    end

    protected

    def client_variable_name
      "#{name}_client".to_sym
    end

    def client_configuration_variable_name
      "#{name}_client_configuration".to_sym
    end

    def client_configuration_changed?
      configuration != RequestStore.store[client_configuration_variable_name]
    end

    def static_client?
      static_configuration? && @static_client.present?
    end
  end
end
