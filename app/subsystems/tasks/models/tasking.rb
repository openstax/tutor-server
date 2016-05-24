class Tasks::Models::Tasking < Tutor::SubSystems::BaseModel
  belongs_to :task, inverse_of: :taskings
  belongs_to :role, subsystem: :entity

  belongs_to :period, -> { with_deleted }, subsystem: :course_membership

  validates :task, presence: true
  validates :role, presence: true, uniqueness: { scope: :tasks_task_id }
end
