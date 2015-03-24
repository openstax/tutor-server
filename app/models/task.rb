class Task < ActiveRecord::Base

  belongs_to :task_plan

  sortable_has_many :task_steps, on: :number,
                                 dependent: :destroy,
                                 autosave: true,
                                 inverse_of: :task
  has_many :taskings, dependent: :destroy

  validates :title, presence: true
  validates :opens_at, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at }, allow_nil: true

  def is_shared
    taskings.size > 1
  end

  def tasked_to?(taskee)
    taskings.where(taskee: taskee).any?
  end

  def completed?
    self.task_steps.all?{|ts| ts.completed? }
  end

end
