module Preview
  class AnswerExercise

    lev_routine

    uses_routine MarkTaskStepCompleted, as: :mark_completed

    protected

    def exec(task_step:, is_correct:, free_response: nil,
             completed: true, completion_time: Time.current)
      tasked = task_step.tasked

      if !tasked.is_a?(::Tasks::Models::TaskedExercise)
        # puts "task:      #{task_step.task.inspect}"
        # puts "task step: #{task_step.inspect}"
        # puts "tasked:    #{tasked.inspect}"
        raise "Cannot answer a #{tasked.class.name} - Group: #{task_step.group_type}"
      end

      if is_correct
        free_response ||= 'A sentence explaining all the things!'
        answer_id = tasked.correct_answer_id
      else
        free_response ||= 'A sentence explaining all the wrong things...'
        wrong_answer_ids = tasked.answer_ids.reject{|id| id == tasked.correct_answer_id}
        raise "No incorrect answers to choose" if wrong_answer_ids.size == 0
        answer_id = wrong_answer_ids.shuffle.first
      end

      tasked.update_attributes(free_response: free_response, answer_id: answer_id)

      run(:mark_completed, task_step: task_step, completion_time: completion_time) if completed
    end

  end
end
