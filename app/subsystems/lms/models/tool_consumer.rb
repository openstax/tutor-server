class Lms::Models::ToolConsumer < Tutor::SubSystems::BaseModel

  before_validation :initialize_tokens

  protected

  def initialize_tokens
    self.key ||= SecureRandom.hex(30)
    self.secret ||= SecureRandom.hex(30)
  end

end

