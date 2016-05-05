class TaskExercise

  lev_routine

  protected

  def exec(exercise:, title: nil, task: nil, task_step: nil)

    # This routine will make one step per exercise part.  If provided, the
    # incoming `task_step` will be used as the first step.

    task ||= task_step.try(:task)
    fatal_error(code: :cannot_get_task) if task.nil?

    current_step = task_step
    current_step ||= Tasks::Models::TaskStep.new

    questions = exercise.content_as_independent_questions

    outputs[:task_steps] = questions.each_with_index.map do |question, ii|
      # Make sure that all steps after the first exercise part get their own new step
      current_step = Tasks::Models::TaskStep.new(number: current_step.number + 1) if ii > 0

      current_step.tasked = Tasks::Models::TaskedExercise.new(
        content_exercise_id: exercise.id,
        url: exercise.url,
        title: title || exercise.title,
        content: question[:content],
        question_id: question[:id],
        is_in_multipart: questions.size > 1
      )

      task.add_step(current_step)

      yield current_step if block_given?

      current_step
    end

    # Task was already saved and we added more steps, so need to reload steps from DB
    task.task_steps.reset if task.persisted? && current_step != task_step
  end

end
