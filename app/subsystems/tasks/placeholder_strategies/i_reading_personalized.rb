class Tasks::PlaceholderStrategies::IReadingPersonalized

  def populate_placeholders(task:)
    personalized_placeholder_task_steps = task.personalized_task_steps(preload_tasked: true)
                                              .select(&:placeholder?)
    return if personalized_placeholder_task_steps.none?

    # Gather relevant pages
    page_ids = task.task_plan.settings['page_ids']
    ecosystem = GetEcosystemFromIds[page_ids: page_ids]
    pages = ecosystem.pages_by_ids(page_ids)

    # Gather exercise pools
    pools = ecosystem.reading_dynamic_pools(pages: pages)

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
      step.save! # the tasked is already saved (step may be too actually)
    end

    task.task_steps.reset
    task
  end

end
