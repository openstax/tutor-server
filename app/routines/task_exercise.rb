class TaskExercise

  lev_routine express_output: :tasked_exercise

  protected

  def exec(exercise:, title: nil, can_be_recovered: false, task_step: nil)
    outputs[:tasked_exercise] = Tasks::Models::TaskedExercise.new(
      task_step: task_step,
      exercise: (exercise.is_a?(Exercise) ? exercise._repository : nil),
      url: exercise.url,
      title: title || exercise.title,
      content: exercise.content,
      can_be_recovered: can_be_recovered
    )
    task_step.tasked = outputs[:tasked_exercise] unless task_step.nil?
  end

end
