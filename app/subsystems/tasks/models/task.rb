class Tasks::Models::Task < ApplicationRecord
  attr_accessor :step_counts_updated

  CACHE_COLUMNS = [
    :steps_count,
    :completed_steps_count,
    :core_steps_count,
    :completed_core_steps_count,
    :exercise_steps_count,
    :completed_exercise_steps_count,
    :correct_exercise_steps_count,
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

  belongs_to :task_plan, inverse_of: :tasks, optional: true

  belongs_to :ecosystem, subsystem: :content, inverse_of: :tasks

  belongs_to :extension, optional: true, inverse_of: :task

  delegate :timezone, :time_zone, to: :course
  has_timezone :opens_at, :due_at, :closes_at, suffix: :ntz

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

  # Concept Coach and Practice Widget tasks have no open, due or close dates
  # We already validate dates for teacher-created assignments in the TaskingPlan
  validates :opens_at_ntz, :due_at_ntz, :closes_at_ntz, timeliness: { type: :date },
            allow_nil: true

  validate :due_at_on_or_after_opens_at, :closes_at_on_or_after_due_at

  before_validation :update_cached_attributes
  after_create :update_caches_now
  after_touch :update_caches_later

  def reload(*args)
    @extension = nil

    super
  end

  def extension
    return @extension unless @extension.nil?

    return if task_plan.nil?

    tasking = taskings.first
    return if tasking.nil?

    @extension = if task_plan.extensions.loaded?
      task_plan.extensions.detect do |extension|
        extension.entity_role_id == tasking.entity_role_id
      end
    elsif tasking.association(:role).loaded? && tasking.role.extensions.loaded?
      tasking.role.extensions.detect do |extension|
        extension.tasks_task_plan_id == tasks_task_plan_id
      end
    else
      task_plan.extensions.find_by entity_role_id: tasking.entity_role_id
    end
  end

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

  alias_method :due_at_without_extension, :due_at
  alias_method :closes_at_without_extension, :closes_at

  def extended?
    !extension.nil?
  end

  def due_at
    [ due_at_without_extension, extension&.due_at ].compact.max
  end

  def closes_at
    [ closes_at_without_extension, extension&.closes_at ].compact.max
  end

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

  def late_work_penalty_per_period
    grading_template&.late_work_penalty || 0.0
  end

  def completion
    steps_count == 0 ? nil : completed_steps_count / steps_count.to_f
  end

  # NOTE: This method does not know the final number of questions assigned
  def available_points_without_dropping_per_question_index
    @available_points_without_dropping_per_question_index ||=
      task_plan&.available_points_without_dropping_per_question_index || Hash.new(1.0)
  end

  # NOTE: This method does not know the final number of questions assigned
  def available_points_per_question_index
    @available_points_per_question_index ||= begin
      available_points_without_dropping_per_question_index
        .dup.tap do |available_points_per_question_index|
        zeroed_question_ids = task_plan&.dropped_questions&.filter(&:zeroed?)&.map(&:question_id)
        next if zeroed_question_ids.blank?
        zeroed_question_ids = Set.new(zeroed_question_ids || [])

        exercise_and_placeholder_steps.each_with_index do |task_step, index|
          available_points_per_question_index[index] = 0.0 \
            if task_step.exercise? && zeroed_question_ids.include?(task_step.tasked.question_id)
        end
      end
    end
  end

  def available_points_without_dropping
    available_points_without_dropping_per_question_index.values_at(
      *actual_and_placeholder_exercise_count.times.to_a
    ).sum
  end

  def available_points
    available_points_per_question_index.values_at(
      *actual_and_placeholder_exercise_count.times.to_a
    ).sum
  end

  def points_per_question_index_without_lateness(incomplete_value_proc: ->(task_step) { 0.0 })
    full_credit_question_ids = Set.new(
      task_plan&.dropped_questions&.filter(&:full_credit?)&.map(&:question_id) || []
    )

    exercise_and_placeholder_steps.each_with_index.map do |task_step, index|
      next incomplete_value_proc.call(task_step) unless task_step.completed? && task_step.exercise?

      tasked = task_step.tasked
      next incomplete_value_proc.call(task_step) \
        if !task_step.tasked.was_manually_graded? && !tasked.can_be_auto_graded?

      next available_points_per_question_index[index] \
        if full_credit_question_ids.include?(tasked.question_id)

      next tasked.grader_points || incomplete_value_proc.call(task_step) \
        if tasked.was_manually_graded? || !tasked.can_be_auto_graded?

      tasked.is_correct? ? available_points_per_question_index[index] : 0.0
    end
  end

  def points_without_lateness
    points_per_question_index_without_lateness.sum
  end

  def late_work_penalty_for(task_step:, due_at: self.due_at)
    return 0.0 if task_step.last_completed_at.nil?

    return 0.0 if due_at.nil? || task_step.last_completed_at <= due_at

    penalty = case late_work_penalty_applied
    when 'immediately'
      late_work_penalty_per_period
    when 'daily'
      ((task_step.last_completed_at - due_at)/1.day).ceil * late_work_penalty_per_period
    else
      0.0
    end
  end

  def late_work_point_penalty
    due_at = self.due_at
    return 0.0 if due_at.nil?

    points_per_question_index_without_lateness = self.points_per_question_index_without_lateness
    exercise_and_placeholder_steps.each_with_index.sum do |task_step, index|
      points = points_per_question_index_without_lateness[index]
      points == 0.0 ? 0.0 : points * late_work_penalty_for(task_step: task_step, due_at: due_at)
    end
  end

  def points
    points_without_lateness - late_work_point_penalty
  end

  def available_points_worked(current_time: Time.current)
    if past_due?(current_time: current_time)
      available_points
    else
      exercise_and_placeholder_steps.each_with_index.sum do |task_step, index|
        task_step.exercise? && task_step.completed? ?
          available_points_per_question_index[index] : 0.0
      end
    end
  end

  def score_without_lateness(current_time: Time.current)
    available_points_worked = self.available_points_worked current_time: current_time

    points_without_lateness/available_points_worked unless available_points_worked == 0.0
  end

  def score(current_time: Time.current)
    available_points_worked = self.available_points_worked current_time: current_time

    points/available_points_worked unless available_points_worked == 0.0
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
    self.core_steps_count = core_steps.count
    self.completed_core_steps_count = completed_core_steps.count
    self.exercise_steps_count = exercise_steps.count
    self.completed_exercise_steps_count = completed_exercise_steps.count
    self.correct_exercise_steps_count = correct_exercise_steps.count
    self.placeholder_steps_count = placeholder_steps.count
    self.placeholder_exercise_steps_count = placeholder_exercise_steps.count
    self.core_placeholder_exercise_steps_count = placeholder_exercise_steps.count(&:is_core?)
    self.core_steps_completed_at ||= current_time if completed_core_steps_count == core_steps_count
    self.ungraded_step_count = exercise_steps.count do |step|
      step.completed? && !step.tasked.can_be_auto_graded? && !step.tasked.was_manually_graded?
    end

    late_after = due_at
    on_time_steps = late_after.nil? ?
      completed_steps : completed_steps.select { |step| step.last_completed_at < late_after }
    self.completed_on_time_steps_count = on_time_steps.count
    self.completed_on_time_exercise_steps_count = on_time_steps.count(&:exercise?)

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

  def past_close?(current_time: Time.current)
    !closes_at.nil? && current_time > closes_at
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
      !grades_last_published_at.nil?
    else
      false
    end
  end

  def manually_graded_steps
    exercise_steps(preload_taskeds: true).reject {|step| step.tasked.can_be_auto_graded? }
  end

  def manual_grading_feedback_available?
    case manual_grading_feedback_on
    when 'grade'
      manually_graded_steps.any? do |task_step|
        task_step.tasked.was_manually_graded?
      end
    when 'publish'
      !grades_last_published_at.nil?
    else
      false
    end
  end

  def manual_grading_complete?
    case manual_grading_feedback_on
    when 'grade'
      manually_graded_steps.all? do |task_step|
        task_step.tasked.was_manually_graded?
      end
    when 'publish'
      manually_graded_steps.all? do |task_step|
        task_step.tasked.grade_published?
      end
    else
      false
    end
  end

  def provisional_score?(current_time: Time.current, current_time_ntz: nil)
    (
      manual_grading_feedback_available? || auto_grading_feedback_available?(
        current_time: current_time, current_time_ntz: current_time_ntz
      )
    ) && !manual_grading_complete?
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

  def exercise_and_placeholder_steps(preload_taskeds: false)
    self.preload_taskeds if preload_taskeds
    task_steps.filter { |step| step.exercise? || step.placeholder? }
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

  def correct_exercise_count
    correct_exercise_steps_count
  end

  protected

  def due_at_on_or_after_opens_at
    return if course.nil? || due_at.nil? || opens_at.nil? || due_at >= opens_at

    errors.add(:due_at, 'must be on or after opens_at')
    throw :abort
  end

  def closes_at_on_or_after_due_at
    return if closes_at.nil? || due_at.nil? || closes_at >= due_at

    errors.add(:closes_at, 'must be on or after due_at')
    throw :abort
  end
end
