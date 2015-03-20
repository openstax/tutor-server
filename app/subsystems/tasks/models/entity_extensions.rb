class Entity::Task < ActiveRecord::Base
  has_many :taskings, subsystem: :tasks
  has_many :legacy_task_maps, subsystem: :tasks
end