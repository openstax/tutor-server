require_relative './api/configuration'
require_relative './api/remote_error'
require_relative './api/fake_client'
require_relative './api/real_client'

module OpenStax::Payments::Api
  extend Configurable
  extend Configurable::ClientMethods

  class << self
    #
    # API Wrappers
    #

    def check_payment(product_instance_uuid:)
      client.check_payment(product_instance_uuid: product_instance_uuid)
    end

    def refund(product_instance_uuid:)
      client.refund(product_instance_uuid: product_instance_uuid)
    end

    def orders_for_account(account)
      client.orders_for_account(account)
    end

    def embed_js_url
      # FIXME: figure out how to get host and port from Rails
      configuration.stub ? 'http://localhost:3001/assets/payments/api-stub.js' :
        Rails.application.secrets.openstax[:payments][:embed_js_url]
    end

    protected

    def new_fake_client
      OpenStax::Payments::Api::FakeClient.new(configuration)
    end

    def new_real_client
      OpenStax::Payments::Api::RealClient.new(configuration)
    end

    def new_configuration
      OpenStax::Payments::Api::Configuration.new
    end
  end
end
