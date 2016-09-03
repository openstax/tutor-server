require_relative './v1/configuration'
require_relative './v1/exceptions'
require_relative './v1/exercise'
require_relative './v1/fake_client'
require_relative './v1/real_client'

module OpenStax::Exercises::V1

  class << self

    #
    # API Wrappers
    #

    # GET /api/exercises
    # options can have :tag, :id, :number, :version keys
    def exercises(options={})
      exercises_json = client.exercises(options)
      exercises_hash = JSON.parse(exercises_json)
      exercises_hash['items'] = exercises_hash['items'].map do |ex|
        OpenStax::Exercises::V1::Exercise.new(content: ex.to_json, server_url: client.server_url)
      end
      exercises_hash
    end

    #
    # Configuration
    #

    def configure
      yield configuration
    end

    # Note: thread-safe only if @configuration already set (must call it in initializers once)
    def configuration
      @configuration ||= Configuration.new
    end

    # Accessor for the fake client, which has some extra fake methods on it
    def fake_client
      FakeClient.instance
    end

    def real_client
      RealClient.new(configuration)
    end

    # Note: not thread-safe, use only in initializers
    def use_real_client
      @client = real_client
    end

    # Note: not thread-safe, use only in initializers
    def use_fake_client
      @client = fake_client
    end

    def server_url
      client.server_url
    end

    def uri_for(path)
      Addressable::URI.join(configuration.server_url, path)
    end

    private

    # Note: thread-safe only if @client already set (must call it in initializers once)
    def client
      @client ||= real_client
    rescue StandardError => error
      raise ClientError.new("initialization failure", error)
    end

  end

end
