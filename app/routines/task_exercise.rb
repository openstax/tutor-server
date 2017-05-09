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

    group_type = current_step.group_type
    related_content = current_step.related_content
    labels = current_step.labels

    questions = exercise.content_as_independent_questions

    outputs[:task_steps] = questions.each_with_index.map do |question, ii|
      # Make sure that all steps after the first exercise part get their own new step
      if ii > 0
        next_step_number = current_step.number.nil? ? nil : current_step.number + 1

        current_step = Tasks::Models::TaskStep.new(
          number: next_step_number, group_type: group_type,
          related_content: related_content, labels: labels
        )
      end

      # Mark the step as incomplete just in case it had been marked as complete before
      current_step.first_completed_at = nil
      current_step.last_completed_at = nil

      current_step.tasked = Tasks::Models::TaskedExercise.new(
        exercise: exercise.to_model,
        url: exercise.url,
        title: title || exercise.title,
        context: exercise.context,
        question_id: question[:id],
        is_in_multipart: questions.size > 1
      )

      current_step.tasked.set_correct_answer_id

      yield current_step if block_given?

      task.add_step(current_step)

      current_step
    end

    # Task was already saved and we added more steps, so need to reload steps from DB
    task.task_steps.reset if task.persisted? && current_step != task_step
  end

end
