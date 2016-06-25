class Tasks::Models::CourseAssistant < Tutor::SubSystems::BaseModel

  belongs_to :course, subsystem: :entity
  belongs_to :assistant

  json_serialize :settings, Hash
  json_serialize :data, Hash

  validates :course, presence: true
  validates :assistant, presence: true, uniqueness: { scope: :entity_course_id }
  validates :tasks_task_plan_type, presence: true,
                                   uniqueness: { scope: :entity_course_id }

end
