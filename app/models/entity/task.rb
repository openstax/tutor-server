class Entity::Task < Tutor::SubSystems::BaseModel
  has_many :taskings, subsystem: :tasks, dependent: :destroy, autosave: true, inverse_of: :task
  has_one :task, subsystem: :tasks, dependent: :destroy, autosave: true, inverse_of: :entity_task
end
