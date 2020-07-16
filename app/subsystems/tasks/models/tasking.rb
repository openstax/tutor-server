class Tasks::Models::Tasking < IndestructibleRecord
  belongs_to :task, inverse_of: :taskings
  belongs_to :role, subsystem: :entity, inverse_of: :taskings

  validates :role, uniqueness: { scope: :tasks_task_id }
end
