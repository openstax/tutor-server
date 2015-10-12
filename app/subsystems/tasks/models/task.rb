require_relative '../placeholder_strategies/homework_personalized'
require_relative '../placeholder_strategies/i_reading_personalized'

class Tasks::Models::Task < Tutor::SubSystems::BaseModel
  enum task_type: [:homework, :reading, :chapter_practice,
                   :page_practice, :mixed_practice, :external,
                   :event, :extra]

  belongs_to :task_plan, inverse_of: :tasks

  # dependent: :destroy will cause and infinite loop and stack overflow
  belongs_to :entity_task, class_name: 'Entity::Task',
                           foreign_key: 'entity_task_id',
                           dependent: :delete,
                           inverse_of: :task

  sortable_has_many :task_steps, on: :number,
                                 dependent: :destroy,
                                 inverse_of: :task,
                                 autosave: true
  has_many :tasked_exercises, through: :task_steps, source: :tasked,
                                                    source_type: 'Tasks::Models::TaskedExercise'
  has_many :taskings, through: :entity_task

  validates :title, presence: true

  validates :opens_at, presence: true, timeliness: { type: :date }

  # Practice Widget can create tasks with no due date
  # We already validate dates for teacher-created assignments in the TaskingPlan
  validates :due_at, timeliness: { type: :date }, allow_nil: true

  validate :due_at_on_or_after_opens_at

  def personalized_placeholder_strategy
    serialized_strategy = read_attribute(:personalized_placeholder_strategy)
    strategy = serialized_strategy.nil? ? nil : YAML.load(serialized_strategy)
    strategy
  end

  def personalized_placeholder_strategy=(strategy)
    serialized_strategy = strategy.nil? ? nil : YAML.dump(strategy)
    write_attribute(:personalized_placeholder_strategy, serialized_strategy)
  end

  def is_shared?
    taskings.size > 1
  end

  def past_open?(current_time: Time.now)
    opens_at.nil? || current_time > opens_at
  end

  def past_due?(current_time: Time.now)
    !due_at.nil? && current_time > due_at
  end

  def feedback_available?(current_time: Time.now)
    !feedback_at.nil? && current_time >= feedback_at
  end

  def completed?
    steps_count == completed_steps_count
  end

  def in_progress?
    completed_steps_count > 0 && !completed?
  end

  def set_last_worked_at(time:)
    self.last_worked_at = time
  end

  def status
    if completed?
      'completed'
    elsif completed_steps_count > 0
      'in_progress'
    else
      'not_started'
    end
  end

  def late?
    worked_on? && last_worked_at > due_at
  end

  def worked_on?
    last_worked_at.present?
  end

  def practice?
    page_practice? || chapter_practice? || mixed_practice?
  end

  def core_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.to_a.select(&:core_group?)
  end

  def non_core_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.to_a - self.core_task_steps
  end

  def spaced_practice_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.to_a.select(&:spaced_practice_group?)
  end

  def personalized_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.to_a.select(&:personalized_group?)
  end

  def core_task_steps_completed?
    core_steps_count == completed_core_steps_count
  end

  def handle_task_step_completion!(completion_time: Time.current)
    set_last_worked_at(time: completion_time)
    update_step_counts!

    if core_task_steps_completed? && placeholder_steps_count > 0
      strategy = personalized_placeholder_strategy
      unless strategy.nil?
        strategy.populate_placeholders(task: self)
      end

      update_step_counts!
    end
  end

  def update_step_counts
    steps = task_steps.to_a

    update_steps_count(task_steps: steps)
    update_completed_steps_count(task_steps: steps)
    update_core_steps_count(task_steps: steps)
    update_completed_core_steps_count(task_steps: steps)
    update_exercise_steps_count(task_steps: steps)
    update_completed_exercise_steps_count(task_steps: steps)
    update_correct_exercise_steps_count(task_steps: steps)
    update_placeholder_steps_count(task_steps: steps)
    update_placeholder_exercise_steps_count(task_steps: steps)

    self
  end

  def update_step_counts!
    update_step_counts.save!
  end

  def exercise_count
    exercise_steps_count
  end

  def actual_and_placeholder_exercise_count
    exercise_steps_count + placeholder_exercise_steps_count
  end

  def completed_exercise_count
    completed_exercise_steps_count
  end

  def correct_exercise_count
    correct_exercise_steps_count
  end

  def exercise_steps
    task_steps.preload(:tasked).select{|task_step| task_step.exercise?}
  end

  protected

  def due_at_on_or_after_opens_at
    return if due_at.nil? || opens_at.nil? || due_at >= opens_at
    errors.add(:due_at, 'must be on or after opens_at')
    false
  end

  def update_steps_count(task_steps:)
    self.steps_count = task_steps.count
  end

  def update_completed_steps_count(task_steps:)
    self.completed_steps_count = task_steps.count(&:completed?)
  end

  def update_core_steps_count(task_steps:)
    self.core_steps_count = task_steps.count(&:core_group?)
  end

  def update_completed_core_steps_count(task_steps:)
    self.completed_core_steps_count =
      task_steps.count{|step| step.core_group? && step.completed?}
  end

  def update_exercise_steps_count(task_steps:)
    self.exercise_steps_count = task_steps.count(&:exercise?)
  end

  def update_completed_exercise_steps_count(task_steps:)
    self.completed_exercise_steps_count =
      task_steps.count{|step| step.exercise? && step.completed?}
  end

  def update_correct_exercise_steps_count(task_steps:)
    self.correct_exercise_steps_count =
      task_steps.count{|step| step.exercise? && step.tasked.is_correct?}
  end

  def update_placeholder_steps_count(task_steps:)
    self.placeholder_steps_count = task_steps.count(&:placeholder?)
  end

  def update_placeholder_exercise_steps_count(task_steps:)
    self.placeholder_exercise_steps_count =
      task_steps.count{|step| step.placeholder? && step.tasked.exercise_type?}
  end

end
