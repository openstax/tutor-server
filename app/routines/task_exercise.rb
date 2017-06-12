class TaskExercise

  lev_routine

  protected

  def exec(exercise:, title: nil, task: nil, task_step: nil)
    # This routine will make one step per exercise part.
    # If provided, the incoming `task_step` will be used as the first step.

    task ||= task_step.try!(:task)
    fatal_error(code: :cannot_get_task) if task.nil?

    exercise_model = exercise.to_model
    page = exercise_model.page

    if task_step.present?
      current_step = task_step
      new_step = !task.task_steps.include?(task_step)
    else
      current_step = Tasks::Models::TaskStep.new page: page
      new_step = true
    end

    group_type = current_step.group_type
    page = current_step.page
    labels = current_step.labels
    spy = current_step.spy
    questions = exercise.content_as_independent_questions

    outputs[:task_steps] = questions.each_with_index.map do |question, ii|
      # Make sure that all steps after the first exercise part get their own new step
      current_step = Tasks::Models::TaskStep.new(
        task: task,
        number: current_step.number.nil? ? nil : current_step.number + 1,
        group_type: group_type,
        page: page,
        labels: labels,
        spy: spy
      ) if ii > 0

      # Mark the step as incomplete just in case it had been marked as complete before
      current_step.first_completed_at = nil
      current_step.last_completed_at = nil

      current_step.tasked = Tasks::Models::TaskedExercise.new(
        exercise: exercise_model,
        url: exercise.url,
        title: title || exercise.title,
        context: exercise.context,
        content: question[:content],
        question_id: question[:id],
        is_in_multipart: questions.size > 1
      )

      current_step.tasked.set_correct_answer_id

      yield current_step if block_given?

      # Add the step to the task's list of steps if it's new
      # Both of these only save the steps if the task or the step are already persisted
      if new_step
        task.task_steps << current_step
      elsif current_step.persisted?
        current_step.save!
      end

      new_step = true

      current_step
    end

    # Task was already saved and we added more steps, so need to reload steps from DB
    task.task_steps.reset if task.persisted? && current_step != task_step
  end

end
