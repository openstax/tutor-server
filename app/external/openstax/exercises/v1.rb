module OpenStax::Exercises::V1

  #
  # API Wrappers
  #

  # GET /api/exercises
  # options can have :tag, :id, :number, :version keys
  def self.exercises(options={})
    JSON.parse(client.exercises(options)).collect{|e|
      OpenStax::Exercises::V1::Exercise.new(e.to_json)
    }
  end

  #
  # Configuration
  #

  # accessor for the fake client, which has some extra fake methods on it
  def self.fake_client
    @fake_client
  end

  def self.use_fake_client
    @client = @fake_client
  end

  # The real client is used by default, so this only exists in case you said
  # use_fake_client but wanted to switch
  def self.use_real_client
    @client = @real_client
  end

  private

  @fake_client = FakeClient.new
  @real_client = RealClient.new

  def self.client
    @client ||= @real_client
  end

end