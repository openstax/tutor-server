class Lms::Models::Context < Tutor::SubSystems::BaseModel
  belongs_to :tool_consumer, subsystem: :lms
  belongs_to :course, subsystem: :course_profile
end
