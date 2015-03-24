class Tasks::Tasking < ActiveRecord::Base
  belongs_to :role, subsystem: :entity
  belongs_to :task, subsystem: :entity

  validates :role, presence: true
  validates :task, presence: true,
                   uniqueness: { scope: :entity_role_id }
end
