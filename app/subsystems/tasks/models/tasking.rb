class Tasks::Models::Tasking < IndestructibleRecord
  belongs_to :task, inverse_of: :taskings
  belongs_to :role, subsystem: :entity, inverse_of: :taskings

  belongs_to :period, subsystem: :course_membership, inverse_of: :taskings, optional: true

  validates :role, uniqueness: { scope: :tasks_task_id }
end
