class FilterExcludedExercises
  lev_routine transaction: :no_transaction, express_output: :exercises

  def exec(
    exercises:,
    task: nil,
    role: nil,
    course: nil,
    additional_excluded_numbers: [],
    current_time: Time.current
  )
    # Assumes tasks only have 1 tasking
    role ||= task&.taskings&.first&.role
    course ||= role&.course_member&.course

    # Get global excluded exercises
    admin_exclusions = Settings::Exercises.excluded_ids.split(',').map(&:strip)
    admin_excluded_uids, admin_excluded_numbers = admin_exclusions.partition do |string|
      string.include? '@'
    end

    # Get course excluded exercises
    course_excluded_numbers = course.nil? ? [] : course.excluded_exercises.map(&:exercise_number)

    # Get exercises excluded due to anti-cheating rules
    anti_cheating_excluded_numbers = if role.nil?
      outputs.already_assigned_exercise_numbers = []
      []
    else
      tasks = role.taskings.preload(task: :course).map(&:task)

      exercise_numbers_by_task_id = Hash.new { |hash, key| hash[key] = [] }
      Content::Models::Exercise
        .joins(tasked_exercises: :task_step)
        .where(tasked_exercises: { task_step: { tasks_task_id: tasks.map(&:id) } })
        .pluck(:tasks_task_id, :number)
        .each do |task_id, number|
        exercise_numbers_by_task_id[task_id] << number
      end

      outputs.already_assigned_exercise_numbers = exercise_numbers_by_task_id.values.flatten.uniq

      # Get tasks are not yet due or do not yet have feedback
      exercise_numbers_by_task_id.values_at(
        *tasks.filter do |task|
          past_due = task.past_due?(current_time: current_time)
          (!task.due_at.nil? && !past_due) ||
          !task.auto_grading_feedback_available?(past_due: past_due)
        end.map(&:id)
      ).flatten.uniq
    end

    admin_excluded_uids_set = Set.new admin_excluded_uids

    admin_excluded_numbers_set = Set.new admin_excluded_numbers.map(&:to_i)
    course_excluded_numbers_set = Set.new course_excluded_numbers
    anti_cheating_excluded_numbers_set = Set.new anti_cheating_excluded_numbers
    additional_excluded_numbers_set = Set.new additional_excluded_numbers.to_a

    outputs.admin_excluded_uids = []
    outputs.course_excluded_uids = []
    outputs.role_excluded_uids = []
    outputs.additional_excluded_uids = []

    outputs.exercises = exercises.select do |ex|
      if admin_excluded_uids_set.include?(ex.uid) || admin_excluded_numbers_set.include?(ex.number)
        outputs.admin_excluded_uids << ex.uid
        next false
      end

      if course_excluded_numbers_set.include?(ex.number)
        outputs.course_excluded_uids << ex.uid
        next false
      end

      if anti_cheating_excluded_numbers_set.include?(ex.number)
        outputs.role_excluded_uids << ex.uid
        next false
      end

      if additional_excluded_numbers_set.include?(ex.number)
        outputs.additional_excluded_uids << ex.uid
        next false
      end

      true
    end
  end
end
