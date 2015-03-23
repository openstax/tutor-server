class Task < ActiveRecord::Base

  belongs_to :task_plan

  sortable_has_many :task_steps, on: :number,
                                 dependent: :destroy,
                                 autosave: true,
                                 inverse_of: :task
  has_many :taskings, dependent: :destroy

  validates :task_plan, presence: true
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

  def start(start_time: Time.now)
    self.started_at = start_time
  end

  def started?
    !self.started_at.nil?
  end

  def core_task_steps
    task_steps.select{|ts| ts.is_core?}
  end

  def core_task_steps_completed?
    core_task_steps.all?{|ts| ts.completed?}
  end

  def completed?
    task_steps.all?{|ts| ts.completed?}
  end

  def completed_at
    return nil if !completed?
    task_steps.collect{|ts| ts.completed_at}.max
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

  def add_spaced_practice_exercises
    self.spaced_practice_algorithm.call(task: self)
  end
end
