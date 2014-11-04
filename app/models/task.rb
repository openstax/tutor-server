class Task < ActiveRecord::Base

  belongs_to :task_plan

  has_many :task_steps, dependent: :destroy
  has_many :taskings, dependent: :destroy
  has_many :users, through: :taskings

  validates :task_plan, presence: true
  validates :title, presence: true
  validates :opens_at, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at }, allow_nil: true
  validates :closes_at, timeliness: { on_or_after: :due_at },
                        allow_nil: true, if: :due_at

  def is_shared
    taskings.size > 1
  end

  def klass
    owner = task_plan.owner
    case owner
    when Educator
      owner.klass
    else
      nil
    end
  end

end
