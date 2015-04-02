require_relative 'entity_extensions'

class Tasks::Models::Task < Tutor::SubSystems::BaseModel

  belongs_to :task_plan
  belongs_to :entity_task, class_name: 'Entity::Task',
                           dependent: :destroy,
                           foreign_key: 'entity_task_id'

  sortable_has_many :task_steps, on: :number,
                                 dependent: :destroy,
                                 autosave: true,
                                 inverse_of: :task
  has_many :taskings, dependent: :destroy, through: :entity_task

  validates :title, presence: true
  validates :opens_at, presence: true
  validates :due_at, timeliness: { on_or_after: :opens_at }, allow_nil: true

  def is_shared
    taskings.size > 1
  end

  def completed?
    self.task_steps.all?{|ts| ts.completed? }
  end

  def core_task_steps
    self.task_steps.select{|ts| ts.core_group?}
  end

  def spaced_practice_task_steps
    self.task_steps.select{|ts| ts.spaced_practice_group?}
  end

  def core_task_steps_completed?
    self.core_task_steps.all?{|ts| ts.completed?}
  end
end
