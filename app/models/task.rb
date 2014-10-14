class Task < ActiveRecord::Base
  has_many :assigned_tasks, dependent: :destroy
  belongs_to :details, polymorphic: true, dependent: :destroy
  belongs_to :task_plan

  def is_shared
    assigned_tasks.size > 1
  end
end
