class Tasks::Models::CourseAssistant < Tutor::SubSystems::BaseModel
  belongs_to :course
  belongs_to :assistant

  serialize :settings
  serialize :data

  validates :course, presence: true
  validates :assistant, presence: true, uniqueness: { scope: :course_id }
end
