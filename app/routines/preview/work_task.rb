module Preview
  class WorkTask

    lev_routine

    uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders
    uses_routine MarkTaskStepCompleted, as: :mark_completed
    uses_routine Preview::AnswerExercise, as: :answer_exercise

    protected

    def exec(task:, is_correct:, free_response: nil, is_completed: true, completed_at: Time.current)
      run(:populate_placeholders, task: task, force: true)

      task.task_steps.preload(:tasked).each_with_index do |task_step, index|
        is_completed_value = is_completed.is_a?(Proc) ? is_completed.call(task, task_step, index) :
                                                        is_completed
        next unless is_completed_value

        completed_at_value = completed_at.is_a?(Proc) ? completed_at.call(task, task_step, index) :
                                                        completed_at

        if task_step.exercise?
          is_correct_value = is_correct.is_a?(Proc) ? is_correct.call(task, task_step, index) :
                                                      is_correct
          free_response_value = free_response.is_a?(Proc) ?
                                  free_response.call(task, task_step, index) : free_response

          run(:answer_exercise, task_step: task_step,         completed_at: completed_at_value,
                                is_correct: is_correct_value, free_response: free_response_value)
        else
          run(:mark_completed, task_step: task_step, completed_at: completed_at_value)
        end
      end
    end

  end
end
