class Lms::Models::ToolConsumer < Tutor::SubSystems::BaseModel
  has_many :contexts, subsystem: :lms, dependent: :destroy

  # Prevent destroys for the time being
  before_destroy -> { false }
end
