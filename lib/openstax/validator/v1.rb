require_relative './v1/configuration'
require_relative './v1/fake_client'
require_relative './v1/real_client'

module OpenStax::Validator::V1
  extend Configurable
  extend Configurable::ClientMethods

  class << self
    # Sends the manifest to validator
    def upload_ecosystem_manifest(ecosystem_or_manifest)
      client.upload_ecosystem_manifest ecosystem_or_manifest

      true
    end

    protected

    def new_fake_client
      OpenStax::Validator::V1::FakeClient.new configuration
    end

    def new_real_client
      OpenStax::Validator::V1::RealClient.new configuration
    end

    def new_configuration
      OpenStax::Validator::V1::Configuration.new
    end
  end
end
