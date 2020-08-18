class Tasks::Models::CourseAssistant < IndestructibleRecord
  belongs_to :course, subsystem: :course_profile
  belongs_to :assistant

  validates :assistant, uniqueness: { scope: :course_profile_course_id }
  validates :tasks_task_plan_type, presence: true, uniqueness: { scope: :course_profile_course_id }
end
