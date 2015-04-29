module OpenStax::BigLearn::V1

  #
  # API Wrappers
  #

  def self.get_clue(learner_ids:, tags:)
    tags = [tags].flatten.compact
    learner_ids = [learner_ids].flatten.compact

    client.get_clue(learner_ids: learner_ids, tags: tags)
  end

  def self.add_exercises(exercises)
    client.add_exercises(exercises)
  end

  # Returns recommended exercises
  #
  # tag_search: a hash describing a boolean search on tags;
  #             exercises that match this search are candidates
  #             to be returned.
  #   Ex:
  #     { _and: [ { _or: ['a', 'b', 'c'] }, 'd']  }
  #
  def self.get_projection_exercises(user:, tag_search: {},
                                    count: 1, difficulty: 0.5, allow_repetitions: true)
    client.get_projection_exercises(user: user, tag_search: tag_search,
                                    count: count, difficulty: difficulty, allow_repetitions: allow_repetitions)
  end

  #
  # Configuration
  #

  def self.configure
    yield configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Accessor for the fake client, which has some extra fake methods on it
  def self.fake_client
    @fake_client ||= FakeClient.new
  end

  def self.real_client
    @real_client ||= RealClient.new
  end

  def self.use_real_client
    @client = real_client
  end

  def self.use_fake_client
    @client = fake_client
  end

  private

  def self.client
    begin
      @client ||= fake_client
    rescue StandardError => error
      raise ClientError.new("initialization failure", error)
    end
  end

end
