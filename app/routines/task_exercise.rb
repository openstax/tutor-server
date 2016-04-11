class TaskExercise

  lev_routine express_output: :tasked_exercise

  protected

  def exec(exercise:, title: nil, task_step: nil)
    outputs[:tasked_exercise] = Tasks::Models::TaskedExercise.new(
      task_step: task_step,
      content_exercise_id: exercise.id,
      url: exercise.url,
      title: title || exercise.title,
      content: exercise.content
    )
    task_step.tasked = outputs[:tasked_exercise] unless task_step.nil?
  end

end
