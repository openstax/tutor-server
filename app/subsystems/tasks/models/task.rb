require_relative 'entity_extensions'

class Tasks::Models::Task < Tutor::SubSystems::BaseModel

  belongs_to :task_plan
  belongs_to :entity_task, class_name: 'Entity::Models::Task',
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
  validates :spaced_practice_algorithm, presence: true

  after_initialize :init

  def init
    self.spaced_practice_algorithm ||= SpacedPracticeAlgorithmDefault.new
  end

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

  def spaced_practice_algorithm
    serialized_algorithm = read_attribute(:spaced_practice_algorithm)
    return nil unless serialized_algorithm
    algorithm = YAML.load(serialized_algorithm)
    algorithm
  end

  def spaced_practice_algorithm=(algorithm)
    raise ArgumentError, "algorithm cannot be nil" if algorithm.nil?
    write_attribute(:spaced_practice_algorithm, YAML.dump(algorithm))
  end

  def handle_task_step_completion!
    spaced_practice_algorithm.call(event: :task_step_completion, task: self)
  end

end
