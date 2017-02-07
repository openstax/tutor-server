require_relative '../placeholder_strategies/homework_personalized'
require_relative '../placeholder_strategies/i_reading_personalized'

class Tasks::Models::Task < Tutor::SubSystems::BaseModel

  class_attribute :skip_update_step_counts_if_due_at_changed
  self.skip_update_step_counts_if_due_at_changed = false

  acts_as_paranoid

  auto_uuid

  enum task_type: [:homework, :reading, :chapter_practice,
                   :page_practice, :mixed_practice, :external,
                   :event, :extra, :concept_coach]

  STEPLESS_TASK_TYPES = [:external, :event]

  json_serialize :spy, Hash

  belongs_to_time_zone :opens_at, :due_at, :feedback_at, suffix: :ntz

  belongs_to :task_plan, -> { with_deleted }, inverse_of: :tasks

  belongs_to :ecosystem, subsystem: :content, inverse_of: :tasks

  sortable_has_many :task_steps, -> { with_deleted.order(:number) },
                                 on: :number, dependent: :destroy, inverse_of: :task
  has_many :tasked_exercises, -> { with_deleted }, through: :task_steps, source: :tasked,
                                                   source_type: 'Tasks::Models::TaskedExercise'

  has_many :taskings, -> { with_deleted }, dependent: :destroy, inverse_of: :task
  has_one :concept_coach_task, -> { with_deleted }, dependent: :destroy, inverse_of: :task

  validates :title, presence: true

  # Concept Coach and Practice Widget tasks have no open or due dates
  # We already validate dates for teacher-created assignments in the TaskingPlan
  validates :opens_at_ntz, :due_at_ntz, :feedback_at_ntz,
            timeliness: { type: :date }, allow_nil: true

  validate :due_at_on_or_after_opens_at

  before_update :update_step_counts_if_due_at_changed

  def touch
    update_step_counts

    # super is not needed here when there are changes because save! will update the timestamp
    changed? ? save_without_update_step_counts_callback!(validate: false) : super
  end

  def add_step(step)
    self.task_steps << step
  end

  def stepless?
    STEPLESS_TASK_TYPES.include?(task_type.to_sym)
  end

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

  def past_open?(current_time: Time.current)
    opens_at.nil? || current_time > opens_at
  end

  def past_due?(current_time: Time.current)
    !due_at.nil? && current_time > due_at
  end

  def feedback_available?(current_time: Time.current)
    feedback_at.nil? || current_time >= feedback_at
  end

  def hidden?
    deleted? && hidden_at.present? && hidden_at >= deleted_at
  end

  def completed?
    steps_count == completed_steps_count
  end

  def in_progress?
    completed_steps_count > 0 && !completed?
  end

  def hide(current_time: Time.current)
    self.hidden_at = current_time
    self
  end

  def set_last_worked_at(time:)
    self.last_worked_at = time
    self
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
    worked_on? && due_at.present? && last_worked_at > due_at
  end

  def worked_on?
    last_worked_at.present?
  end

  def practice?
    page_practice? || chapter_practice? || mixed_practice?
  end

  def preview?
    taskings.none?{ |tasking| tasking.role.try!(:student?) }
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
    if core_task_steps_completed? && placeholder_steps_count > 0
      strategy = personalized_placeholder_strategy
      unless strategy.nil?
        strategy.populate_placeholders(task: self)
      end
    end

    set_last_worked_at(time: completion_time).save!
  end

  def update_step_counts
    steps = persisted? ? task_steps.reload.preload(:tasked).to_a : task_steps.to_a

    update_steps_count(task_steps: steps)
    update_completed_steps_count(task_steps: steps)
    update_completed_on_time_steps_count(task_steps: steps)
    update_core_steps_count(task_steps: steps)
    update_completed_core_steps_count(task_steps: steps)
    update_exercise_steps_count(task_steps: steps)
    update_completed_exercise_steps_count(task_steps: steps)
    update_completed_on_time_exercise_steps_count(task_steps: steps)
    update_correct_exercise_steps_count(task_steps: steps)
    update_correct_on_time_exercise_steps_count(task_steps: steps)
    update_placeholder_steps_count(task_steps: steps)
    update_placeholder_exercise_steps_count(task_steps: steps)

    self
  end

  def save_without_update_step_counts_callback!(*args)
    self.skip_update_step_counts_if_due_at_changed = true
    save!(*args)
  ensure
    self.skip_update_step_counts_if_due_at_changed = false
  end

  def update_step_counts!(*args)
    update_step_counts

    save_without_update_step_counts_callback!(*args)
  end

  def update_step_counts_if_due_at_changed
    return true if skip_update_step_counts_if_due_at_changed || !due_at_changed?

    update_step_counts
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

  def completed_on_time_exercise_count
    completed_on_time_exercise_steps_count
  end

  def completed_accepted_late_exercise_count
    completed_accepted_late_exercise_steps_count
  end

  def correct_exercise_count
    correct_exercise_steps_count
  end

  def correct_on_time_exercise_count
    correct_on_time_exercise_steps_count
  end

  def correct_accepted_late_exercise_count
    correct_accepted_late_exercise_steps_count
  end

  def exercise_steps
    task_steps.preload(:tasked).select(&:exercise?)
  end

  def effective_correct_exercise_count
    correct_on_time_exercise_count + correct_accepted_late_exercise_count
  end

  def score
    effective_correct_exercise_count / actual_and_placeholder_exercise_count.to_f rescue nil
  end

  def accept_late_work
    self.correct_accepted_late_exercise_steps_count =
      correct_exercise_steps_count - correct_on_time_exercise_steps_count
    self.completed_accepted_late_exercise_steps_count =
      completed_exercise_steps_count - completed_on_time_exercise_steps_count
    self.completed_accepted_late_steps_count =
      completed_steps_count - completed_on_time_steps_count
    self.accepted_late_at = Time.current
  end

  def reject_late_work
    self.correct_accepted_late_exercise_steps_count = 0
    self.completed_accepted_late_exercise_steps_count = 0
    self.completed_accepted_late_steps_count = 0
    self.accepted_late_at = nil
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

  def update_completed_on_time_steps_count(task_steps:)
    self.completed_on_time_steps_count =
      task_steps.count{|step| step.completed? && step_on_time?(step)}
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

  def update_completed_on_time_exercise_steps_count(task_steps:)
    self.completed_on_time_exercise_steps_count =
      task_steps.count{|step| step.exercise? && step.completed? && step_on_time?(step)}
  end

  def update_correct_exercise_steps_count(task_steps:)
    self.correct_exercise_steps_count =
      task_steps.count{|step| step.exercise? && step.tasked.is_correct?}
  end

  def update_correct_on_time_exercise_steps_count(task_steps:)
    self.correct_on_time_exercise_steps_count =
      task_steps.count do |step|
        step.exercise? && step.completed? &&
        step.tasked.is_correct? && step_on_time?(step)
      end
  end

  def update_placeholder_steps_count(task_steps:)
    self.placeholder_steps_count = task_steps.count(&:placeholder?)
  end

  def update_placeholder_exercise_steps_count(task_steps:)
    self.placeholder_exercise_steps_count =
      task_steps.count{|step| step.placeholder? && step.tasked.exercise_type?}
  end

  def step_on_time?(step)
    due_at.nil? || step.last_completed_at < due_at
  end

end
