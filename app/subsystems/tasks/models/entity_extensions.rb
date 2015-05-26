Entity::Task.has_many :taskings, subsystem: :tasks, dependent: :destroy
Entity::Task.has_one :task, subsystem: :tasks, dependent: :destroy
