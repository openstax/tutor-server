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
      tasks   = role.taskings
                  .joins(:task)
                  .where.not(task: { task_type: Tasks::Models::Task::PRACTICE_TASK_TYPES } )
                  .preload(task: :course).map(&:task)
      taskeds = Tasks::Models::TaskedExercise
                  .joins(:exercise, task_step: :task)
                  .where(task_step: { task: { id: tasks.map(&:id) } })
                  .preload(:exercise, task_step: { task: { task_plan: :grading_template } })

      outputs.already_assigned_exercise_numbers = taskeds.map {|t| t.exercise.number }.flatten.uniq

      # Get tasks are not yet due or do not yet have feedback
      [].tap do |excluded|
        taskeds.map {|t| excluded << t.exercise.number unless t.feedback_available? }
      end.uniq
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
