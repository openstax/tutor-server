class Tasks::Models::LegacyTaskMap < Tutor::SubSystems::BaseModel
  belongs_to :task, subsystem: :entity
  belongs_to :legacy_task, class_name: 'Task',
                           foreign_key: 'task_id'

  validates :task, presence: true,
                   uniqueness: { scope: :task_id }
  validates :legacy_task, presence: true
end
