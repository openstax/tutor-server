class Tasks::Models::Tasking < Tutor::SubSystems::BaseModel

  acts_as_paranoid

  belongs_to :task, -> { with_deleted }, inverse_of: :taskings
  belongs_to :role, subsystem: :entity, inverse_of: :taskings

  belongs_to :period, -> { with_deleted }, subsystem: :course_membership, inverse_of: :taskings

  validates :task, presence: true
  validates :role, presence: true, uniqueness: { scope: :tasks_task_id }

end
