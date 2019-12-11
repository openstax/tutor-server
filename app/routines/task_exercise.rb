class TaskExercise
  lev_routine transaction: :read_committed

  protected

  def exec(
    exercise:, task: nil, task_steps: nil, title: nil, allow_save: true,
    group_type: nil, is_core: nil, labels: nil, spy: nil, fragment_index: nil
  )
    # This routine will make one step per exercise part.
    # If provided, the incoming `task_steps` will be used.

    if task_steps.nil?
      raise ArgumentError if task.nil? || group_type.nil? || is_core.nil?

      max_num_questions = nil
    else
      task ||= task_steps.first&.task
      raise ArgumentError if task.nil?

      max_num_questions = task_steps.size
    end

    questions = exercise.questions
    is_in_multipart = exercise.is_multipart?
    questions = questions.first(max_num_questions) unless max_num_questions.nil?
    outputs.task_steps = questions.each_with_index.map do |question, question_index|
      # Make sure that all exercise parts get their own step
      if task_steps.nil?
        current_step = Tasks::Models::TaskStep.new(
          task: task,
          number: current_step.nil? ? nil : current_step.number + 1,
          page: exercise.page,
          group_type: group_type,
          is_core: is_core
        )
        is_new_step = true
      else
        current_step = task_steps[question_index]
        current_step.page = exercise.page
        current_step.group_type = group_type unless group_type.nil?
        current_step.is_core = is_core unless is_core.nil?
        is_new_step = !task.task_steps.include?(current_step)
      end

      current_step.fragment_index = fragment_index unless fragment_index.nil?
      current_step.labels = labels unless labels.nil?
      current_step.spy = spy unless spy.nil?

      # Mark the step as incomplete just in case it had been marked as complete before
      current_step.first_completed_at = nil
      current_step.last_completed_at = nil

      current_step.tasked = Tasks::Models::TaskedExercise.new(
        exercise: exercise,
        url: exercise.url,
        title: title || exercise.title,
        question_id: question.id,
        question_index: question_index,
        answer_ids: exercise.question_answer_ids[question_index],
        is_in_multipart: is_in_multipart
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
    task.task_steps.reset if task.persisted? && task_steps.nil?
  end
end
