class Tasks::Models::Task < ApplicationRecord
  attr_accessor :step_counts_updated

  CACHE_COLUMNS = [
    :steps_count,
    :completed_steps_count,
    :completed_on_time_steps_count,
    :core_steps_count,
    :completed_core_steps_count,
    :exercise_steps_count,
    :completed_exercise_steps_count,
    :completed_on_time_exercise_steps_count,
    :correct_exercise_steps_count,
    :correct_on_time_exercise_steps_count,
    :placeholder_steps_count,
    :placeholder_exercise_steps_count,
  ]

  acts_as_paranoid column: :hidden_at, without_default_scope: true

  auto_uuid

  enum task_type: [
    :homework, :reading, :chapter_practice,
    :page_practice, :mixed_practice, :external,
    :event, :extra, :concept_coach, :practice_worst_topics
  ]

  STEPLESS_TASK_TYPES = [ :external, :event ]

  json_serialize :spy, Hash

  belongs_to_time_zone :opens_at, :due_at, suffix: :ntz, optional: true

  belongs_to :task_plan, inverse_of: :tasks, optional: true

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
  has_many :roles, through: :taskings, subsystem: :entity
  has_many :students, through: :roles, subsystem: :course_membership
  has_many :research_cohorts, through: :students,
           subsystem: :research, class_name: 'Research::Models::Cohort'
  has_many :research_study_brains, -> { student_task },
           through: :research_cohorts, source: :study_brains,
           subsystem: :research, class_name: 'Research::Models::StudyBrain'

  has_one :concept_coach_task, inverse_of: :task

  validates :title, presence: true

  # Concept Coach and Practice Widget tasks have no open or due dates
  # We already validate dates for teacher-created assignments in the TaskingPlan
  validates :opens_at_ntz, :due_at_ntz, timeliness: { type: :date }, allow_nil: true

  validate :due_at_on_or_after_opens_at

  before_validation :update_cached_attributes
  after_create :update_caches_now
  after_touch :update_caches_later

  def grading_template
    task_plan&.grading_template
  end

  def completion_weight
    grading_template&.completion_weight || (reading? ? 0.9 : 0.0)
  end

  def correctness_weight
    grading_template&.correctness_weight || (reading? ? 0.1 : 1.0)
  end

  def auto_grading_feedback_on
    grading_template&.auto_grading_feedback_on || 'answer'
  end

  def manual_grading_feedback_on
    grading_template&.manual_grading_feedback_on || 'grade'
  end

  def late_work_penalty_applied
    grading_template&.late_work_penalty_applied || 'never'
  end

  def late_work_penalty
    grading_template&.late_work_penalty || 0.0
  end

  def is_preview
    task_plan.present? && task_plan.is_preview
  end

  def update_cached_attributes(steps: nil)
    steps ||= persisted? && !task_steps.loaded? ? task_steps.preload(:tasked) : task_steps
    steps = steps.to_a

    completed_steps = steps.select(&:completed?)
    core_steps = steps.select(&:is_core?)
    completed_core_steps = completed_steps & core_steps
    exercise_steps = steps.select(&:exercise?)
    completed_exercise_steps = completed_steps & exercise_steps

    correct_exercise_steps = exercise_steps.select { |step| step.tasked.is_correct? }

    placeholder_steps = steps.select(&:placeholder?)
    placeholder_exercise_steps = placeholder_steps.select { |step| step.tasked.exercise_type? }

    self.core_page_ids = core_steps.map(&:content_page_id).uniq
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
    self.placeholder_exercise_steps_count = placeholder_exercise_steps.count
    self.core_placeholder_exercise_steps_count = placeholder_exercise_steps.count(&:is_core?)

    self
  end

  def update_caches_now(update_cached_attributes: false)
    Tasks::UpdateTaskCaches.call(task_ids: id, update_cached_attributes: update_cached_attributes)
  end

  def update_caches_later(update_cached_attributes: true)
    queue = is_preview ? :preview : :dashboard
    Tasks::UpdateTaskCaches.set(queue: queue).perform_later(
      task_ids: id, update_cached_attributes: update_cached_attributes, queue: queue.to_s
    )
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

  def auto_grading_feedback_available?(current_time: Time.current, current_time_ntz: nil)
    case auto_grading_feedback_on
    when 'answer'
      true
    when 'due'
      if current_time_ntz.nil?
        !due_at.nil? && current_time >= due_at
      else
        !due_at_ntz.nil? && current_time_ntz >= due_at_ntz
      end
    when 'publish'
      false
    else
      false
    end
  end

  def manual_grading_feedback_available?
    case manual_grading_feedback_on
    when 'grade'
      false
    when 'publish'
      false
    else
      false
    end
  end

  def withdrawn?
    !task_plan.nil? && task_plan.withdrawn?
  end

  def hidden?
    deleted? && withdrawn? && hidden_at >= task_plan.withdrawn_at
  end

  def started?(use_cache: false)
    if use_cache
      completed_steps_count > 0
    else
      task_steps.loaded? ? task_steps.any?(&:completed?) : task_steps.complete.exists?
    end
  end

  def completed?(use_cache: false)
    if use_cache
      completed_steps_count == steps_count
    else
      task_steps.loaded? ? task_steps.all?(&:completed?) : !task_steps.incomplete.exists?
    end
  end

  def in_progress?(use_cache: false)
    started?(use_cache: use_cache) && !completed?(use_cache: use_cache)
  end

  def status(use_cache: false)
    if completed?(use_cache: use_cache)
      'completed'
    elsif started?(use_cache: use_cache)
      'in_progress'
    else
      'not_started'
    end
  end

  def core_task_steps_completed?
    task_steps.loaded? ? core_task_steps.all?(&:completed?) : !task_steps.core.incomplete.exists?
  end

  def hide(current_time: Time.current)
    self.hidden_at = current_time
    self
  end

  def set_last_worked_at(last_worked_at:)
    self.last_worked_at = last_worked_at
    self
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
    taskings.none? { |tasking| tasking.role&.student? }
  end

  def core_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.filter(&:is_core?)
  end

  def dynamic_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.to_a.reject(&:is_core?)
  end

  def fixed_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.filter(&:fixed_group?)
  end

  def personalized_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.filter(&:personalized_group?)
  end

  def spaced_practice_task_steps(preload_tasked: false)
    task_steps = preload_tasked ? self.task_steps.preload(:tasked) : self.task_steps
    task_steps.filter(&:spaced_practice_group?)
  end

  def handle_task_step_completion!(completed_at: Time.current)
    set_last_worked_at(last_worked_at: completed_at).save!
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

  def completion
    steps_count == 0 ? nil : completed_steps_count / steps_count.to_f
  end

  def correctness
    actual_and_placeholder_exercise_count == 0 ?
      nil : correct_exercise_count / actual_and_placeholder_exercise_count.to_f
  end

  def lateness
    return 0 if last_worked_at.blank? || due_at.blank?

    last_worked_at - [ due_at, accepted_late_at ].compact.max
  end

  def score
    result_without_lateness = 0

    if completion_weight > 0
      return if completion.nil?

      result_without_lateness += completion * completion_weight
    end

    if correctness_weight > 0
      return if correctness.nil?

      result_without_lateness += correctness * correctness_weight
    end

    return result_without_lateness if lateness <= 0

    penalty = case late_work_penalty_applied
    when 'immediately'
      late_work_penalty
    when 'daily'
      (lateness/1.day).ceil * late_work_penalty
    else
      0.0
    end

    return 0.0 if penalty >= 1.0

    (1.0 - penalty) * result_without_lateness
  end

  def accept_late_work
    self.completed_accepted_late_steps_count = completed_steps_count
    self.completed_accepted_late_exercise_steps_count = completed_exercise_steps_count
    self.correct_accepted_late_exercise_steps_count = correct_exercise_steps_count
    self.accepted_late_at = Time.current
  end

  def reject_late_work
    self.completed_accepted_late_steps_count = 0
    self.completed_accepted_late_exercise_steps_count = 0
    self.correct_accepted_late_exercise_steps_count = 0
    self.accepted_late_at = nil
  end

  protected

  def due_at_on_or_after_opens_at
    return if due_at.nil? || opens_at.nil? || due_at >= opens_at

    errors.add(:due_at, 'must be on or after opens_at')
    throw :abort
  end

  def step_on_time?(step)
    due_at.nil? || (step.last_completed_at.present? && step.last_completed_at < due_at)
  end
end
