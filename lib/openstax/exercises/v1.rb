require_relative './v1/configuration'
require_relative './v1/exceptions'
require_relative './v1/exercise'
require_relative './v1/fake_client'
require_relative './v1/real_client'

module OpenStax::Exercises::V1

  extend Configurable
  extend Configurable::ClientMethods

  class << self

    #
    # API Wrappers
    #

    # GET /api/exercises
    # options can have :tag, :id, :number, :version keys
    def exercises(options={})
      exercises_hash = client.exercises(options)
      exercises_hash['items'].map do |ex|
        OpenStax::Exercises::V1::Exercise.new(content: ex.to_json, server_url: client.server_url)
      end
    end

    def use_fake_client
      self.client = new_fake_client
    end

    def use_real_client
      self.client = new_real_client
    end

    def server_url
      client.server_url
    end

    def uri_for(path)
      Addressable::URI.join(configuration.server_url, path)
    end

    protected

    def new_fake_client
      OpenStax::Exercises::V1::FakeClient.new(configuration)
    end

    def new_real_client
      OpenStax::Exercises::V1::RealClient.new(configuration)
    end

    def new_configuration
      OpenStax::Exercises::V1::Configuration.new
    end

    def new_client
      configuration.stub ? new_fake_client : new_real_client
    rescue StandardError => error
      raise OpenStax::Exercises::ClientError.new("initialization failure", error)
    end

  end

end
