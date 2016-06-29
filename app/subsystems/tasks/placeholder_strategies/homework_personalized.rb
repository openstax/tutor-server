class Tasks::PlaceholderStrategies::HomeworkPersonalized

  def populate_placeholders(task:)
    personalized_placeholder_task_steps = task.personalized_task_steps(preload_tasked: true)
                                              .select(&:placeholder?)
    return if personalized_placeholder_task_steps.none?

    # Gather relevant pages
    exercise_ids = task.task_plan.settings['exercise_ids']
    ecosystem = GetEcosystemFromIds[exercise_ids: exercise_ids]
    exercises = ecosystem.exercises_by_ids(exercise_ids)
    pages = exercises.map(&:page).uniq

    # Gather exercise pools
    pools = ecosystem.homework_dynamic_pools(pages: pages)

    num_placeholders = personalized_placeholder_task_steps.count

    role = task.taskings.first.role

    chosen_exercises = GetEcosystemExercisesFromBiglearn[ecosystem:         ecosystem,
                                                         role:              role,
                                                         pools:             pools,
                                                         count:             num_placeholders,
                                                         difficulty:        0.5,
                                                         allow_repetitions: true]

    task_step_chosen_exercise_pairs = personalized_placeholder_task_steps.zip(chosen_exercises)
    task_step_chosen_exercise_pairs.each do |step, exercise|
      # If no exercise available, hard-delete the TaskStep and the TaskedPlaceholder
      next step.really_destroy! if exercise.nil?

      # Otherwise, hard-delete just the TaskedPlaceholder
      step.tasked.really_destroy!

      TaskExercise[task_step: step, exercise: exercise]
      # inject_debug_content!(step.tasked, "This exercise is part of the #{step.group_type}")
      step.save! # the tasked is already saved (step may be too, actually)
    end

    task.task_steps.reset
    task
  end

end
