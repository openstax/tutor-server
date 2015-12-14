class TaskExercise

  lev_routine outputs: { tasked_exercise: :_self }

  protected

  def exec(exercise:, title: nil, can_be_recovered: false, task_step: nil)
    set(tasked_exercise: Tasks::Models::TaskedExercise.new(
      task_step: task_step,
      content_exercise_id: exercise.id,
      url: exercise.url,
      title: title || exercise.title,
      content: exercise.content,
      can_be_recovered: can_be_recovered
    ))
    task_step.tasked = result.tasked_exercise unless task_step.nil?
  end

end
