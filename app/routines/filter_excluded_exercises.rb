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
    admin_excluded_ids, admin_excluded_numbers = admin_exclusions.partition { |ex| ex.include? '@' }

    # Get course excluded exercises
    course_excluded_numbers = course.nil? ? [] : course.excluded_exercises.map(&:exercise_number)

    role_excluded_numbers = if role.nil?
      outputs.worked_exercise_numbers = []
      []
    else
      # Get tasks are not yet due or do not yet have feedback
      tasks = role.taskings.preload(task: :time_zone).map(&:task)

      exercise_numbers_by_task_id = Hash.new { |hash, key| hash[key] = [] }
      Content::Models::Exercise
        .joins(tasked_exercises: :task_step)
        .where(tasked_exercises: { task_step: { tasks_task_id: tasks.map(:&:id) } })
        .pluck(:tasks_task_id, :number)
        .each do |task_id, number|
        exercise_numbers_by_task_id[task_id] << number
      end

      outputs.worked_exercise_numbers = exercise_numbers_by_task_id.values.flatten.uniq

      exercise_numbers_by_task_id.values_at(
        *tasks.filter do |task|
          (!task.due_at.nil? && !task.past_due?(current_time: current_time)) ||
          !task.feedback_available?(current_time: current_time)
        end.map(&:id)
      ).flatten.uniq
    end

    excluded_exercise_numbers_set = Set.new(
      admin_excluded_numbers.map(&:to_i) +
      course_excluded_numbers +
      role_excluded_numbers +
      additional_excluded_numbers.to_a
    )

    admin_excluded_ids_set = Set.new admin_excluded_ids

    outputs.exercises = exercises.reject do |ex|
      excluded_exercise_numbers_set.include?(ex.number) || admin_excluded_ids_set.include?(ex.uid)
    end
  end
end
