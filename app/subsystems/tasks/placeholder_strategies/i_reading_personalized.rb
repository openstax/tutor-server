class Tasks::PlaceholderStrategies::IReadingPersonalized

  def populate_placeholders(task:)
    personalized_placeholder_task_steps = task.personalized_task_steps.select(&:placeholder?)
    return if personalized_placeholder_task_steps.none?

    num_placeholders = personalized_placeholder_task_steps.count

    taskee = task.taskings.first.role

    los = task.los

    exercise_urls = OpenStax::Biglearn::V1.get_projection_exercises(
      role:              taskee,
      tag_search:        biglearn_condition(los),
      count:             num_placeholders,
      difficulty:        0.5,
      allow_repetitions: true
    )

    chosen_exercises = SearchLocalExercises[url: exercise_urls]
    raise "could not fill all placeholder slots (expected #{num_placeholders} exercises, got #{chosen_exercises.count}) from urls #{exercise_urls}" \
      unless chosen_exercises.count == num_placeholders

    chosen_exercise_task_step_pairs = chosen_exercises.zip(personalized_placeholder_task_steps)
    chosen_exercise_task_step_pairs.each do |exercise, step|
      step.tasked.destroy!
      tasked_exercise = TaskExercise[task_step: step, exercise: exercise]
      # inject_debug_content!(step.tasked, "This exercise is part of the #{step.group_type}")
      tasked_exercise.save!
      step.save!
    end

    task.save!
    task
  end

  def biglearn_condition(los)
    condition = {
      _and: [
        'os-practice-concepts',
        {
          _or: los
        }
      ]
    }

    condition
  end

end
