class Lms::Models::App < Tutor::SubSystems::BaseModel

  belongs_to :owner, polymorphic: true

  before_validation :initialize_tokens

  validates :owner, presence: true

  protected

  def initialize_tokens
    self.key ||= SecureRandom.hex(30)
    self.secret ||= SecureRandom.hex(30)
  end

end

