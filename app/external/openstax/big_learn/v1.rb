module OpenStax::BigLearn::V1

  #
  # API Wrappers
  #

  def self.add_tags(tags)
    client.add_tags(tags)
  end

  def self.add_exercises(exercises)
    client.add_exercises(exercises)
  end

  def self.get_projection_exercises(user:, topic_tags:, filter_tags: [], 
                                    count: 1, difficulty: 0.5, allow_repetitions: true)
    client.get_projection_exercises(user: user, topic_tags: topic_tags, filter_tags: filter_tags, 
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
    @fake_client ||= FakeClient.instance
  end

  def self.real_client
    @real_client ||= RealClient.new(configuration)
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
      @client ||= real_client
    rescue StandardError => error
      raise ClientError.new("initialization failure", error)
    end
  end

end
