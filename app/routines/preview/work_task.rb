class Preview::WorkTask
  lev_routine

  uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders
  uses_routine MarkTaskStepCompleted, as: :mark_completed
  uses_routine Preview::AnswerExercise, as: :answer_exercise

  include Ratings::Concerns::RatingJobs

  protected

  def exec(
    task:,
    is_correct:,
    free_response: nil,
    is_completed: true,
    completed_at: Time.current
  )
    task.lock!

    task.preload_taskeds

    task_was_completed = task.completed?(use_cache: true)

    run :populate_placeholders, task: task, force: true, save: false

    task_steps = task.task_steps.to_a

    task_steps.each_with_index do |task_step, index|
      is_completed_value = is_completed.is_a?(Proc) ? is_completed.call(task_step, index) :
                                                      is_completed
      # Steps in readings cannot be skipped, so once the first
      # incomplete step is reached, skip all following steps
      (task.reading? ? break : next) unless is_completed_value

      completed_at_value = completed_at.is_a?(Proc) ? completed_at.call(task_step, index) :
                                                      completed_at
      # Can't rework steps after feedback date or if manually graded
      next unless task_step.can_be_updated?(current_time: completed_at)

      if task_step.exercise?
        is_correct_value = is_correct.is_a?(Proc) ? is_correct.call(task_step, index) : is_correct
        free_response_value = free_response.is_a?(Proc) ?
          free_response.call(task_step, index, is_correct_value) : free_response

        run(
          :answer_exercise,
          task_step: task_step,
          completed_at: completed_at_value,
          is_correct: is_correct_value,
          free_response: free_response_value,
          lock_task: false,
          save: false
        )
      else
        run(
          :mark_completed,
          task_step: task_step,
          completed_at: completed_at_value,
          lock_task: false,
          save: false
        )
      end
    end

    exercise_steps = task_steps.select(&:exercise?)
    tasked_exercises = exercise_steps.map(&:tasked)
    Tasks::Models::TaskedExercise.import tasked_exercises, validate: false,
                                                           on_duplicate_key_update: {
      conflict_target: [ :id ],
      columns: [ :attempt_number, :free_response, :answer_id, :grader_points, :last_graded_at ]
    }

    Tasks::Models::TaskStep.import task_steps, validate: false, on_duplicate_key_update: {
      conflict_target: [ :id ], columns: [ :first_completed_at, :last_completed_at ]
    }

    task.save!

    role = task.taskings.first&.role
    period = role&.course_member&.period
    course = period&.course

    # course will only be set if role and period were found
    return if course.nil? || task.completed_exercise_steps_count == 0 || task_was_completed

    perform_rating_jobs_later(
      task: task,
      role: role,
      period: period,
      event: :work,
      lock_task: false,
      current_time: completed_at
    )
  end
end
