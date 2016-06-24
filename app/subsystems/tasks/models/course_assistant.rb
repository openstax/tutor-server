class Tasks::Models::CourseAssistant < Tutor::SubSystems::BaseModel

  belongs_to :course, subsystem: :entity
  belongs_to :assistant

  serialize :settings, JSON
  serialize :data, JSON

  after_initialize :enforce_settings_and_data_types

  validates :course, presence: true
  validates :assistant, presence: true, uniqueness: { scope: :entity_course_id }
  validates :tasks_task_plan_type, presence: true,
                                   uniqueness: { scope: :entity_course_id }

  protected

  def enforce_settings_and_data_types
    self.settings = settings.to_h unless settings.is_a?(Hash)
    self.data = data.to_h unless settings.is_a?(Hash)
  end

end
