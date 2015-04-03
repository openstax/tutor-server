class Domain::TaskExercise

  lev_routine express_output: :tasked_exercise

  protected

  def exec(exercise:, has_recovery: false, task_step: nil)
    outputs[:tasked_exercise] = Tasks::Models::TaskedExercise.new(
      task_step: task_step,
      exercise: (exercise.is_a?(Content::Models::Exercise) ? exercise : nil),
      url: exercise.url,
      title: exercise.title,
      content: exercise.content,
      has_recovery: has_recovery
    )
    task_step.tasked = outputs[:tasked_exercise] unless task_step.nil?
  end

end
