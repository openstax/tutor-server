module Hacks
  class AnswerExercise
    lev_routine

    protected

    def exec(task_step:, is_correct:)
      tasked = task_step.tasked
      raise "Task step isn't an exercise" if !tasked.is_a?(Tasks::Models::TaskedExercise)

      answer_id = if is_correct
        tasked.correct_answer_id
      else
        wrong_answer_ids = tasked.answer_ids.reject{|id| id == tasked.correct_answer_id}
        raise "No incorrect answers to choose" if wrong_answer_ids.size == 0
        wrong_answer_ids.first
      end

      tasked.update_attributes(free_response: '.', answer_id: answer_id)

      MarkTaskStepCompleted[task_step: task_step]
      # task_step.update_attributes(completed_at: Time.now)
    end
  end
end
