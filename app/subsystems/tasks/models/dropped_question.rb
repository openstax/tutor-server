class Tasks::Models::DroppedQuestion < ApplicationRecord
  belongs_to :task_plan, inverse_of: :dropped_questions

  enum drop_method: [ :zeroed, :full_credit ]

  validates :question_id, presence: true, uniqueness: { scope: :tasks_task_plan_id }
  validates :drop_method, presence: true
end
