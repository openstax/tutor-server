class Lms::Models::StubbedApp
  attr_reader :key, :secret

  # This app is passed the course's original environment on initialization
  # It is used with ::Api::V1::Lms::LinkingRepresenter to return a stubbed response
  def initialize(environment)
    @key = @secret = "Copied from #{environment.name}"
  end
end
