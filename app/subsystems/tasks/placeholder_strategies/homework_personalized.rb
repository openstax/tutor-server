class Tasks::PlaceholderStrategies::HomeworkPersonalized

  def populate_placeholders(task:)
    personalized_placeholder_task_steps = task.personalized_task_steps(preload_tasked: true)
                                              .select(&:placeholder?)
    num_placeholders = personalized_placeholder_task_steps.length

    return if num_placeholders == 0

    chosen_exercises = OpenStax::Biglearn::Api.fetch_assignment_pes(
      task: task, max_exercises_to_return: num_placeholders
    )

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
