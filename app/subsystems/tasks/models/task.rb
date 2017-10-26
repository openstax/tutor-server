class Tasks::Models::Task < ApplicationRecord

  acts_as_paranoid column: :hidden_at, without_default_scope: true

  class_attribute :skip_update_step_counts_if_due_at_changed
  self.skip_update_step_counts_if_due_at_changed = false

  auto_uuid

  enum task_type: [:homework, :reading, :chapter_practice,
                   :page_practice, :mixed_practice, :external,
                   :event, :extra, :concept_coach, :practice_worst_topics]

  STEPLESS_TASK_TYPES = [:external, :event]

  json_serialize :spy, Hash

  belongs_to_time_zone :opens_at, :due_at, :feedback_at, suffix: :ntz

  belongs_to :task_plan, inverse_of: :tasks

  belongs_to :ecosystem, subsystem: :content, inverse_of: :tasks

  sortable_has_many :task_steps, on: :number, inverse_of: :task do
    # Because we update task_step counts in the middle of the following methods,
    # we cause the task_steps to reload and these methods behave oddly (giving us duplicate records)
    # So we reset after we call them to fix this issue
    def <<(*records)
      result = super
      @association.owner.new_record? ? result : reset
    end

    alias_method :append, :<<
    alias_method :concat, :<<
    alias_method :push, :<<
  end
  has_many :tasked_exercises, through: :task_steps, source: :tasked,
                                                    source_type: 'Tasks::Models::TaskedExercise'

  has_many :taskings, inverse_of: :task
  has_one :concept_coach_task, inverse_of: :task

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

    Tasks::UpdateTaskPageCaches.perform_later(tasks: self)
  end

  def stepless?
    STEPLESS_TASK_TYPES.include?(task_type.to_sym)
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

  def withdrawn?
    !task_plan.nil? && task_plan.withdrawn?
  end

  def hidden?
    deleted? && withdrawn? && hidden_at >= task_plan.withdrawn_at
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

  def set_last_worked_at(last_worked_at:)
    self.last_worked_at = last_worked_at
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
    page_practice? || chapter_practice? || mixed_practice? || practice_worst_topics?
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

  def handle_task_step_completion!(completed_at: Time.current)
    set_last_worked_at(last_worked_at: completed_at).save!
  end

  def update_step_counts
    steps = persisted? ? task_steps.reload.to_a : task_steps.to_a

    completed_steps = steps.select(&:completed?)
    core_steps = steps.select(&:core_group?)
    completed_core_steps = completed_steps & core_steps
    exercise_steps = steps.select(&:exercise?)
    completed_exercise_steps = completed_steps & exercise_steps

    correct_exercise_steps = if persisted?
      tasked_exercise_ids = exercise_steps.map(&:tasked_id)
      correct_tasked_exercise_ids = Tasks::Models::TaskedExercise
                                      .correct
                                      .where(id: tasked_exercise_ids)
                                      .pluck(:id)
      exercise_steps.select { |step| correct_tasked_exercise_ids.include? step.tasked_id }
    else
      exercise_steps.select { |step| step.tasked.is_correct? }
    end

    placeholder_steps = steps.select(&:placeholder?)

    self.steps_count = steps.count
    self.completed_steps_count = completed_steps.count
    self.completed_on_time_steps_count = completed_steps.count { |step| step_on_time?(step) }
    self.core_steps_count = core_steps.count
    self.completed_core_steps_count = completed_core_steps.count
    self.exercise_steps_count = exercise_steps.count
    self.completed_exercise_steps_count = completed_exercise_steps.count
    self.completed_on_time_exercise_steps_count = completed_exercise_steps.count do |step|
      step_on_time?(step)
    end
    self.correct_exercise_steps_count = correct_exercise_steps.count
    self.correct_on_time_exercise_steps_count = correct_exercise_steps.count do |step|
      step_on_time?(step)
    end
    self.placeholder_steps_count = placeholder_steps.count

    self.placeholder_exercise_steps_count = if persisted?
      tasked_placeholder_ids = placeholder_steps.map(&:tasked_id)
      exercise_placeholder_ids = Tasks::Models::TaskedPlaceholder
                                   .exercise_type
                                   .where(id: tasked_placeholder_ids)
                                   .pluck(:id)
      placeholder_steps.count { |step| exercise_placeholder_ids.include? step.tasked_id }
    else
      placeholder_steps.count { |step| step.tasked.exercise_type? }
    end

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

  def step_on_time?(step)
    due_at.nil? || (step.last_completed_at.present? && step.last_completed_at < due_at)
  end

end
