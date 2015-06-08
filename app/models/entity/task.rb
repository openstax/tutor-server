class Entity::Task < Tutor::SubSystems::BaseModel
  has_many :taskings, subsystem: :tasks, dependent: :destroy
  has_one :task, subsystem: :tasks, dependent: :destroy
end
