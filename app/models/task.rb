class Task < ActiveRecord::Base
  has_many :assigned_tasks, dependent: :destroy
  has_one :user, through: :assigned_tasks

  belongs_to :taskable, polymorphic: true
  belongs_to :details, polymorphic: true, dependent: :destroy
  belongs_to :task_plan

  validates :details, presence: true
  validates :title, presence: true
  validates :opens_at, presence: true
  validates :due_at, timeliness: { after: :opens_at }, allow_nil: true

  def is_shared
    assigned_tasks.size > 1
  end
end
