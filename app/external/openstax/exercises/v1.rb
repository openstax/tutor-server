module OpenStax::Exercises::V1

  #
  # API Wrappers
  #

  # GET /api/exercises
  # options can have :tag, :id, :number, :version keys
  def self.exercises(options={})
    exercises_json = client.exercises(options)
    exercises_hash = JSON.parse(exercises_json)
    exercises_hash['items'] = exercises_hash['items'].collect{|e|
      OpenStax::Exercises::V1::Exercise.new(e.to_json)
    }
    exercises_hash
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
