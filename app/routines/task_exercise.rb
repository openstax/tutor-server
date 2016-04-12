class TaskExercise

  lev_routine express_output: :tasked_exercise

  protected

  def exec(exercise:, title: nil, task: nil, task_step: nil)
    # TODO do the splitting of the Exercise here if it is MPQ; if MPQ and there
    # is a task_step, use it, then insert new ones.  Try to get away from returning
    # tasked_exercises and steps unless we switch to returning arrays

    # call exercise.content.split_parts --> get 1..4 JSON strings, iterate over
    # (maybe cache in Content::Exercise so don't have to parse over and over)
    # question: what to do about ID?

    task_step ||= Tasks::Models::TaskStep.new
    task ||= task_step.task

    raise(IllegalArgument, "`task` can only be nil if the step has a task") if task.nil?

    outputs[:tasked_exercise] = Tasks::Models::TaskedExercise.new(
      content_exercise_id: exercise.id,
      url: exercise.url,
      title: title || exercise.title,
      content: exercise.content
    )

    task_step.tasked = outputs[:tasked_exercise]
    task.add_step(task_step)
    outputs[:task_step] = task_step

    yield task_step if block_given?
  end

end
