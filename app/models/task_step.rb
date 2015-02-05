class TaskStep < ActiveRecord::Base
  sortable_belongs_to :task, on: :number, inverse_of: :task_steps
  belongs_to :step, polymorphic: true, dependent: :destroy

  validates :task, presence: true
  validates :step, presence: true
  validates :step_id, uniqueness: { scope: :step_type }

  def complete
    self.completed_at ||= Time.now
  end

  def completed?
    !self.completed_at.nil?
  end
end
