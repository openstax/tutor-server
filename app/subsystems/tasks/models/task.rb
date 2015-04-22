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
  validates :due_at, timeliness: { on_or_after: :opens_at },
                     allow_nil: true,
                     if: :opens_at
  validates :spaced_practice_algorithm, presence: true

  validate :opens_at_or_due_at

  after_initialize :init

  def init
    self.spaced_practice_algorithm ||= SpacedPracticeAlgorithmDoNothing.new
  end

  def is_shared?
    taskings.size > 1
  end

  def past_due?(current_time: Time.now)
    !due_at.nil? && current_time > due_at
  end

  def feedback_available?(current_time: Time.now)
    !feedback_at.nil? && current_time >= feedback_at
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

  def core_task_steps_completed_at
    return nil unless self.core_task_steps_completed?
    self.core_task_steps.collect{|ts| ts.completed_at}.max
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

  def handle_task_step_completion!(completion_time: Time.now)
    self.populate_spaced_practice_exercises!(event: :task_step_completion, current_time: completion_time)
  end

  def populate_spaced_practice_exercises!(event: :force, current_time: Time.now)
    spaced_practice_algorithm.call(event: event, task: self, current_time: current_time)
  end

  protected

  def opens_at_or_due_at
    return unless opens_at.blank? && due_at.blank?
    errors.add(:base, 'needs either the opens_at date or due_at date')
    false
  end

end
