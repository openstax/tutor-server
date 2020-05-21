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

  belongs_to :course, subsystem: :course_profile, inverse_of: :tasks

  belongs_to :course, subsystem: :course_profile, optional: true # Remove optional after migration

  belongs_to :course, subsystem: :course_profile, optional: true # Remove optional after migration

  belongs_to :task_plan, inverse_of: :tasks, optional: true

  belongs_to :ecosystem, subsystem: :content, inverse_of: :tasks

  delegate :timezone, :time_zone, to: :course
  has_timezone :opens_at, :due_at, :feedback_at, suffix: :ntz

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
  validates :opens_at_ntz, :due_at_ntz, :feedback_at_ntz,
            timeliness: { type: :date }, allow_nil: true

  validate :due_at_on_or_after_opens_at

  before_validation :update_cached_attributes
  after_create :update_caches_now
  after_touch :update_caches_later

  def preload_taskeds
    ActiveRecord::Associations::Preloader.new.preload task_steps.to_a, :tasked

    self
  end

  def preload_exercise_content(preload_taskeds: true)
    self.preload_taskeds if preload_taskeds

    tasked_exercises = task_steps.filter(&:exercise?).map(&:tasked)
    ActiveRecord::Associations::Preloader.new.preload tasked_exercises, :exercise

    self
  end

  def preload_reading_content(preload_taskeds: false)
    self.preload_taskeds if preload_taskeds

    ActiveRecord::Associations::Preloader.new.preload task_steps.filter(&:reading?), :page

    self
  end

  def preload_content
    preload_exercise_content

    preload_reading_content

    self
  end

  def goal_num_pes
    task_steps.personalized_group.to_a.count { |step| step.exercise? || step.placeholder? }
  end

  def goal_num_spes
    task_steps.spaced_practice_group.to_a.count { |step| step.exercise? || step.placeholder? }
  end

  def is_preview
    task_plan.present? && task_plan.is_preview
  end

  def update_cached_attributes(steps: nil, current_time: Time.current)
    steps ||= preload_taskeds.task_steps
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

    self.core_steps_completed_at ||= current_time if completed_core_steps_count == core_steps_count

    self
  end

  def update_caches_now(update_cached_attributes: false)
    Tasks::UpdateTaskCaches.call(
      task_ids: id, update_cached_attributes: update_cached_attributes, background: false
    )
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

  def feedback_available?(current_time: Time.current)
    feedback_at.nil? || current_time >= feedback_at
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

  def exercise_steps(preload_taskeds: false)
    self.preload_taskeds if preload_taskeds
    task_steps.filter(&:exercise?)
  end

  def core_task_steps(preload_taskeds: false)
    self.preload_taskeds if preload_taskeds
    task_steps.filter(&:is_core?)
  end

  def dynamic_task_steps(preload_taskeds: false)
    self.preload_taskeds if preload_taskeds
    task_steps.to_a.reject(&:is_core?)
  end

  def fixed_task_steps(preload_taskeds: false)
    self.preload_taskeds if preload_taskeds
    task_steps.filter(&:fixed_group?)
  end

  def personalized_task_steps(preload_taskeds: false)
    self.preload_taskeds if preload_taskeds
    task_steps.filter(&:personalized_group?)
  end

  def spaced_practice_task_steps(preload_taskeds: false)
    self.preload_taskeds if preload_taskeds
    task_steps.filter(&:spaced_practice_group?)
  end

  def handle_task_step_completion(completed_at: Time.current)
    self.last_worked_at = completed_at
    self
  end

  def handle_task_step_completion!(completed_at: Time.current)
    handle_task_step_completion(completed_at: completed_at).save!
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

  def effective_correct_exercise_count
    [ correct_on_time_exercise_count, correct_accepted_late_exercise_count ].max
  end

  def effective_completed_steps_count
    [ completed_on_time_steps_count, completed_accepted_late_steps_count ].max
  end

  def score
    actual_and_placeholder_exercise_count == 0 ?
      nil : effective_correct_exercise_count / actual_and_placeholder_exercise_count.to_f
  end

  def progress
    steps_count == 0 ? nil : effective_completed_steps_count / steps_count.to_f
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
    return if course.nil? || due_at.nil? || opens_at.nil? || due_at >= opens_at

    errors.add(:due_at, 'must be on or after opens_at')
    throw :abort
  end

  def step_on_time?(step)
    due_at.nil? || (step.last_completed_at.present? && step.last_completed_at < due_at)
  end
end
