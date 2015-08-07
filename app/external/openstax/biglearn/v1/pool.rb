class OpenStax::Biglearn::V1::Pool

  attr_reader :exercises
  attr_accessor :uuid

  def initialize(exercises: [], uuid: nil)
    @exercises = exercises
    @uuid = uuid
  end


end
