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

    # POST /api/exercises/search
    # options can have :tag, :uid, :number, :version keys
    def exercises(query = {}, &block)
      seen_uuids = Set.new
      total_exercises = 0
      page = 1

      loop do
        exercises_hash = client.exercises query.merge(page: page)
        total_count = exercises_hash['total_count']
        break if total_count == 0

        exercise_hashes = exercises_hash['items']
        num_exercises = exercise_hashes.size
        break if num_exercises == 0

        new_exercise_hashes = exercise_hashes.reject { |hash| seen_uuids.include? hash['uuid'] }
        seen_uuids += new_exercise_hashes.map { |hash| hash['uuid'] }

        block.call(
          exercise_hashes.map do |ex|
            OpenStax::Exercises::V1::Exercise.new(
              content: ex.to_json,
              server_url: client.server_url
            )
          end
        )

        total_exercises += num_exercises
        break if total_exercises >= total_count
        page += 1
      end

      total_exercises
    end

    def use_fake_client(&block)
      previous_client = client

      begin
        self.client = new_fake_client
        block.call
      ensure
        self.client = previous_client
      end
    end

    def use_real_client(&block)
      previous_client = client

      begin
        self.client = new_real_client
        block.call
      ensure
        self.client = previous_client
      end
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
