class Tasks::FetchAssignmentSpes
  NON_RANDOM_K_AGOS = [ 1, 3, 5 ]
  RANDOM_K_AGOS = [ 2, 4 ]

  DEFAULT_NUM_SPES_PER_K_AGO = 1

  MIN_HISTORY_SIZE_FOR_RANDOM_AGO = 5

  lev_routine express_output: :exercises, transaction: :read_committed

  uses_routine FilterExcludedExercises, as: :filter_excluded_exercises
  uses_routine ChooseExercises,         as: :choose_exercises

  # Returns a number of recommended personalized exercises for the given task using Glicko ratings
  def exec(task:, max_num_exercises: nil, current_time: Time.current)
    case task.task_type
    when 'reading', 'homework'
      pool_type = "#{task.task_type}_dynamic".to_sym
    when 'chapter_practice', 'page_practice', 'mixed_practice', 'practice_worst_topics'
      pool_type = :practice_widget
    else
      outputs.exercises = []
      return
    end

    student_history_tasks = Tasks::Models::Task
      .select(:id, :content_ecosystem_id, :core_page_ids)
      .joins(:taskings, :course)
      .where(
        taskings: { entity_role_id: task.taskings.map(&:entity_role_id) },
        task_type: task.task_type
      )
    student_history_tasks = student_history_tasks.where.not(core_steps_completed_at: nil).or(
      student_history_tasks.where(
        <<~WHERE_SQL
          TIMEZONE("course_profile_courses"."timezone", "tasks_tasks"."due_at_ntz") <= '#{
            current_time.to_s(:db)
          }'
        WHERE_SQL
      )
    ).order(
      Arel.sql(
        <<~ORDER_SQL
          LEAST(
            "tasks_tasks"."core_steps_completed_at",
            TIMEZONE("course_profile_courses"."timezone", "tasks_tasks"."due_at_ntz")
          ) DESC
        ORDER_SQL
      )
    ).preload(:ecosystem).first(6)

    student_history = ([ task ] + student_history_tasks).uniq

    spaced_tasks_num_exercises = get_k_ago_map(
      task: task, include_random_ago: student_history.size > MIN_HISTORY_SIZE_FOR_RANDOM_AGO
    ).map do |k_ago, num_exercises|
      [ student_history[k_ago || RANDOM_K_AGOS.sample] || task, num_exercises ]
    end

    spaced_tasks = spaced_tasks_num_exercises.map(&:first).compact

    ecosystem_map = Content::Map.find_or_create_by(
      from_ecosystems: ([ task.ecosystem ] + spaced_tasks.map(&:ecosystem)).uniq,
      to_ecosystem: task.ecosystem
    )

    page_ids = (task.core_page_ids + spaced_tasks.flat_map(&:core_page_ids)).uniq
    exercise_ids_by_page_id = ecosystem_map.map_page_ids_to_exercise_ids(
      page_ids: page_ids, pool_type: pool_type
    )
    exercises_by_id = Content::Models::Exercise.where(
      id: exercise_ids_by_page_id.values.flatten
    ).index_by(&:id)

    outputs.initially_eligible_exercise_uids = exercises_by_id.values
                                                              .flatten
                                                              .sort_by(&:number)
                                                              .map(&:uid)
    outputs.admin_excluded_uids = []
    outputs.course_excluded_uids = []
    outputs.role_excluded_uids = []
    chosen_exercises = []
    remaining = spaced_tasks_num_exercises.sum(&:second)
    spaced_tasks_num_exercises.each do |spaced_task, num_exercises|
      exercise_ids = exercise_ids_by_page_id.values_at(
        *spaced_task.core_page_ids
      ).compact.flatten
      exercises = filter_and_choose_exercises(
        exercises: exercises_by_id.values_at(*exercise_ids),
        task: task,
        count: num_exercises,
        additional_excluded_numbers: chosen_exercises.map(&:number),
        current_time: current_time
      )

      remaining -= exercises.size

      chosen_exercises.concat exercises
    end

    if remaining > 0
      # Use personalized exercises if not enough spaced practice exercises available
      exercise_ids = exercise_ids_by_page_id.values_at(*task.core_page_ids).compact.flatten
      chosen_exercises.concat filter_and_choose_exercises(
        exercises: exercises_by_id.values_at(*exercise_ids),
        task: task,
        count: remaining,
        additional_excluded_numbers: chosen_exercises.map(&:number),
        current_time: current_time
      )
    end

    outputs.exercises = chosen_exercises.first(max_num_exercises || task.goal_num_spes)
  end

  protected

  def get_k_ago_map(task:, include_random_ago: false)
    # Entries in the list have the form: [from-this-many-tasks-ago, pick-this-many-exercises]
    num_spes = task.goal_num_spes

    case num_spes
    when Integer
      return [] if num_spes == 0

      # Subtract 1 for random-ago/personalized
      num_spes -= 1
      num_spes_per_k_ago, remainder = num_spes.divmod NON_RANDOM_K_AGOS.size

      [].tap do |k_ago_map|
        NON_RANDOM_K_AGOS.each_with_index do |k_ago, index|
          num_k_ago_spes = index < remainder ? num_spes_per_k_ago + 1 : num_spes_per_k_ago

          k_ago_map << [k_ago, num_k_ago_spes] if num_k_ago_spes > 0
        end

        k_ago_map << [(include_random_ago ? nil : 0), 1]
      end
    when NilClass
      # Default
      NON_RANDOM_K_AGOS.map do |k_ago|
        [k_ago, DEFAULT_NUM_SPES_PER_K_AGO]
      end.compact.tap do |k_ago_map|
        k_ago_map << [(include_random_ago ? nil : 0), 1]
      end
    else
      raise ArgumentError, "Invalid assignment num_spes: #{num_spes.inspect}", caller
    end
  end

  def filter_and_choose_exercises(
    exercises:,
    task:,
    count:,
    additional_excluded_numbers: [],
    current_time: Time.current
  )
    # Assumes tasks only have 1 tasking
    role ||= task&.taskings&.first&.role

    # Always exclude all exercises already assigned to the current task
    excluded_exercise_ids = task.exercise_steps(preload_taskeds: true)
                                .map(&:tasked)
                                .map(&:content_exercise_id)

    additional_excluded_numbers += Content::Models::Exercise.where(
      id: excluded_exercise_ids
    ).pluck(:number)

    outs = run(
      :filter_excluded_exercises,
      exercises: exercises,
      task: task,
      role: role,
      additional_excluded_numbers: additional_excluded_numbers,
      current_time: current_time
    ).outputs

    outputs.admin_excluded_uids = (outputs.admin_excluded_uids + outs.admin_excluded_uids).sort.uniq
    outputs.course_excluded_uids = (
      outputs.course_excluded_uids + outs.course_excluded_uids
    ).sort.uniq
    outputs.role_excluded_uids = (
      outputs.role_excluded_uids + outs.role_excluded_uids
    ).sort.uniq

    run(
      :choose_exercises,
      exercises: outs.exercises,
      role: role,
      count: count,
      already_assigned_exercise_numbers: outs.already_assigned_exercise_numbers
    ).outputs.exercises
  end
end
