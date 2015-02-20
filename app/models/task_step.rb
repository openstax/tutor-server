class TaskStep < ActiveRecord::Base
  sortable_belongs_to :task, on: :number, inverse_of: :task_steps
  belongs_to :tasked, polymorphic: true, dependent: :destroy

  validates :task, presence: true
  validates :tasked, presence: true
  validates :tasked_id, uniqueness: { scope: :tasked_type }

  def complete
    self.completed_at ||= Time.now
  end

  def completed?
    !self.completed_at.nil?
  end
end
