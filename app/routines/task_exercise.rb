class TaskExercise

  lev_routine transaction: :read_committed

  protected

  def exec(exercise:, task: nil, task_step: nil, title: nil, allow_save: true)
    # This routine will make one step per exercise part.
    # If provided, the incoming `task_step` will be used as the first step.

    task ||= task_step.try!(:task)
    fatal_error(code: :cannot_get_task) if task.nil?

    if task_step.nil?
      current_step = Tasks::Models::TaskStep.new
      is_new_step = true
    else
      current_step = task_step
      is_new_step = !task.task_steps.include?(task_step)
    end

    exercise_model = exercise.to_model
    page = exercise_model.page
    current_step.page = page

    group_type = current_step.group_type
    labels = current_step.labels
    spy = current_step.spy

    questions = exercise.content_as_independent_questions
    outputs.task_steps = questions.each_with_index.map do |question, ii|
      # Make sure that all steps after the first exercise part get their own new step
      if ii > 0
        current_step = Tasks::Models::TaskStep.new(
          task: task,
          number: current_step.number.nil? ? nil : current_step.number + 1,
          group_type: group_type,
          page: page,
          labels: labels,
          spy: spy
        )
        is_new_step = true
      end

      # Mark the step as incomplete just in case it had been marked as complete before
      current_step.first_completed_at = nil
      current_step.last_completed_at = nil

      current_step.tasked = Tasks::Models::TaskedExercise.new(
        exercise: exercise_model,
        url: exercise.url,
        title: title || exercise.title,
        context: exercise.context,
        question_id: question[:id],
        question_index: ii,
        content: question[:content],
        is_in_multipart: questions.size > 1
      )

      current_step.tasked.set_correct_answer_id

      yield current_step if block_given?

      # Add the step to the task's list of steps if it's new
      # Both of these only save the steps if the task or the step are already persisted
      if allow_save
        if is_new_step
          task.task_steps << current_step
        elsif current_step.persisted?
          current_step.save!
        end
      end

      current_step
    end

    outputs.tasked_exercises = outputs.task_steps.map(&:tasked)

    # Task was already saved and we added more steps, so need to reload steps from DB
    task.task_steps.reset if task.persisted? && current_step != task_step
  end

end
