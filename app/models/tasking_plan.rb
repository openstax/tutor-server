class TaskingPlan < ActiveRecord::Base
  belongs_to :task_plan
  belongs_to :target, polymorphic: true

  validates :target, presence: true
  validates :task_plan, presence: true,
                        uniqueness: { scope: [:target_type, :target_id] }
end
