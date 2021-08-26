class Tasks::Models::TaskStep < ApplicationRecord
  sortable_belongs_to :task, on: :number, inverse_of: :task_steps, touch: true
  belongs_to :tasked, polymorphic: true, dependent: :destroy, inverse_of: :task_step, touch: true
  belongs_to :page, subsystem: :content, inverse_of: :task_steps, optional: true

  enum group_type: [
    :unknown_group,
    :fixed_group,
    :spaced_practice_group,
    :personalized_group,
    :recovery_group
  ]

  json_serialize :related_exercise_ids, Integer, array: true
  json_serialize :labels, String, array: true
  json_serialize :spy, Hash

  validates :tasked_id, uniqueness: { scope: :tasked_type }
  validates :group_type, presence: true
  validates :fragment_index,
            numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_nil: true }

  delegate :can_be_answered?, :has_correctness?, :has_content?, to: :tasked

  scope :complete,   -> do
    completed = left_outer_joins(
      task: { task_plan: :grading_template }
    ).where.not(first_completed_at: nil)
    completed_exercise = completed.where(tasked_type: Tasks::Models::TaskedExercise.name)

    completed.where.not(tasked_type: Tasks::Models::TaskedExercise.name).or(
      completed_exercise.where(
        task: { task_plan: { grading_template: { allow_auto_graded_multiple_attempts: nil } } }
      )
    ).or(
      completed_exercise.where(
        task: { task_plan: { grading_template: { allow_auto_graded_multiple_attempts: false } } }
      )
    ).or(
      completed_exercise.where(
        task: { task_plan: { grading_template: { allow_auto_graded_multiple_attempts: true } } }
      ).where(
        Tasks::Models::TaskedExercise.where(
          '"tasks_tasked_exercises"."id" = "tasks_task_steps"."tasked_id"'
        ).where(
          <<~WHERE_SQL
            "tasks_tasked_exercises"."attempt_number" >=
              GREATEST(CARDINALITY("tasks_tasked_exercises"."answer_ids") - 2, 1)
          WHERE_SQL
        ).arel.exists
      )
    )
  end
  scope :incomplete, -> do
    rel = left_outer_joins(task: { task_plan: :grading_template })

    rel.where(first_completed_at: nil).or(
      rel.where.not(first_completed_at: nil).where(
        tasked_type: Tasks::Models::TaskedExercise.name
      ).where(
        task: { task_plan: { grading_template: { allow_auto_graded_multiple_attempts: true } } }
      ).where(
        Tasks::Models::TaskedExercise.where(
          '"tasks_tasked_exercises"."id" = "tasks_task_steps"."tasked_id"'
        ).where(
          <<~WHERE_SQL
            "tasks_tasked_exercises"."attempt_number" <
              GREATEST(CARDINALITY("tasks_tasked_exercises"."answer_ids") - 2, 1)
          WHERE_SQL
        ).arel.exists
      )
    )
  end

  scope :core,       -> { where is_core: true  }
  scope :dynamic,    -> { where is_core: false }

  scope :exercises,  -> { where tasked_type: Tasks::Models::TaskedExercise.name }

  # Lock the task instead, but don't explode if task is nil
  def lock!(*args)
    task&.lock! *args

    super
  end

  def is_dynamic?
    !is_core?
  end

  def reading?
    tasked_type == Tasks::Models::TaskedReading.name
  end

  def exercise?
    tasked_type == Tasks::Models::TaskedExercise.name
  end

  def placeholder?
    tasked_type == Tasks::Models::TaskedPlaceholder.name
  end

  def external?
    tasked_type == Tasks::Models::TaskedExternalUrl.name
  end

  def is_correct?
    has_correctness? ? tasked.is_correct? : nil
  end

  def can_be_recovered?
    related_exercise_ids.any?
  end

  def make_correct!
    raise "Does not have correctness" unless has_correctness?
    tasked.make_correct!
  end

  def make_incorrect!
    raise "Does not have correctness" unless has_correctness?
    tasked.make_incorrect!
  end

  def complete(completed_at: Time.current)
    valid?
    tasked.valid?
    catch(:abort) { tasked.before_completion }
    tasked.errors.full_messages.each { |message| errors.add :tasked, message }
    return if errors.any?

    self.first_completed_at ||= completed_at
    self.last_completed_at = completed_at

    task.handle_task_step_completion completed_at: completed_at
  end

  def complete!(completed_at: Time.current)
    complete completed_at: completed_at

    save!

    task.save!
  end

  def completed?
    !first_completed_at.nil? && (
      !exercise? || # Non-exercise steps are considered completed after marked
      !tasked.has_answers? || # WRQs are considered completed after first attempt
      !task.allow_auto_graded_multiple_attempts || # Single attempt if multiple attempts is disabled
      tasked.answer_id == tasked.correct_answer_id || # Completed when correct
      tasked.attempt_number >= tasked.max_attempts # Completed after max_attempts are exhausted
    )
  end

  def was_completed?
    !first_completed_at_was.nil? && (
      !exercise? || # Non-exercise steps are considered completed after marked
      !tasked.has_answers? || # WRQs are considered completed after first attempt
      !task.allow_auto_graded_multiple_attempts || # Single attempt if multiple attempts is disabled
      tasked.answer_id_was == tasked.correct_answer_id || # Completed when correct
      tasked.attempt_number_was >= tasked.max_attempts # Completed after max_attempts are exhausted
    )
  end

  def update_error(current_time: Time.current)
    # Closed assignments cannot be updated
    return 'task closed' if task.past_close?(current_time: current_time)

    # Graded exercises cannot be updated
    return 'already graded' if exercise? && tasked.was_manually_graded?

    # Incomplete steps that are not closed or graded can always be updated
    return unless was_completed?

    # Completed non-exercises cannot be updated
    return 'already completed' unless exercise?

    # Completed exercises can be updated before feedback is available
    tasked.feedback_available?(current_time: current_time) ? 'solution already available' : nil
  end

  def can_be_updated?(current_time: Time.current)
    update_error(current_time: Time.current).nil?
  end

  def group_name
    group_type.sub(/_group\z/, '').gsub('_', ' ')
  end

  def related_content
    page.nil? ? [] : [ page.related_content ]
  end

  def spy_with_response_validation
    return spy unless exercise? && tasked.response_validation.present?

    spy.merge response_validation: tasked.response_validation
  end
end
