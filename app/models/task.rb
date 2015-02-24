class Task < ActiveRecord::Base

  belongs_to :task_plan

  has_many :task_steps, dependent: :destroy, autosave: true, inverse_of: :task
  has_many :taskings, dependent: :destroy

  validates :task_plan, presence: true
  validates :title, presence: true
  validates :opens_at, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at }, allow_nil: true

  def is_shared
    taskings.size > 1
  end

  def course
    owner = task_plan.owner
    case owner
    when Educator
      owner.course
    else
      nil
    end
  end

  def tasked_to?(taskee)
    taskings.where(taskee: taskee).any?
  end
end
