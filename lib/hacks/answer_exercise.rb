module Hacks
  class AnswerExercise
    lev_routine

    uses_routine MarkTaskStepCompleted, as: :mark_completed

    protected

    def exec(task_step:, is_correct:, free_response: nil, completed: true)
      tasked = task_step.tasked
      raise "Task step isn't an exercise" if !tasked.is_a?(Tasks::Models::TaskedExercise)

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

      run(:mark_completed, task_step: task_step) if completed
    end
  end
end
