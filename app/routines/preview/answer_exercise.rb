class Preview::AnswerExercise
  lev_routine

  uses_routine MarkTaskStepCompleted, as: :mark_completed

  protected

  def exec(
    task_step:,
    is_correct:,
    free_response: nil,
    is_completed: true,
    completed_at: Time.current,
    lock_task: true,
    save: true
  )
    tasked = task_step.tasked

    if !tasked.is_a?(::Tasks::Models::TaskedExercise)
      # puts "task:      #{task_step.task.inspect}"
      # puts "task step: #{task_step.inspect}"
      # puts "tasked:    #{tasked.inspect}"
      raise "Cannot answer a #{tasked.class.name} - Group: #{task_step.group_type}"
    end

    if is_correct
      free_response = 'A sentence explaining all the things!' if free_response.blank?
      answer_id = tasked.correct_answer_id
    else
      free_response = 'A sentence explaining all the wrong things...' if free_response.blank?
      wrong_answer_ids = tasked.answer_ids.reject { |id| id == tasked.correct_answer_id }
      answer_id = wrong_answer_ids.shuffle.first
    end

    tasked.free_response = free_response
    tasked.answer_id = answer_id
    tasked.save! if save

    run(
      :mark_completed,
      task_step: task_step,
      completed_at: completed_at,
      lock_task: lock_task,
      save: save
    ) if is_completed
  end
end
