class Preview::WorkTask
  lev_routine

  uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders
  uses_routine MarkTaskStepCompleted, as: :mark_completed
  uses_routine Preview::AnswerExercise, as: :answer_exercise

  protected

  def exec(
    task:,
    is_correct:,
    free_response: nil,
    is_completed: true,
    completed_at: Time.current,
    update_caches: true
  )
    task.preload_taskeds

    run :populate_placeholders, task: task, force: true, background: true

    task_steps = task.task_steps.to_a

    task_steps.each_with_index do |task_step, index|
      is_completed_value = is_completed.is_a?(Proc) ? is_completed.call(task_step, index) :
                                                      is_completed
      # Steps in readings cannot be skipped, so once the first
      # incomplete step is reached, skip all following steps
      (task.reading? ? break : next) unless is_completed_value

      completed_at_value = completed_at.is_a?(Proc) ? completed_at.call(task_step, index) :
                                                      completed_at
      # Can't rework steps after feedback date
      next if task_step.completed? && task.feedback_available?(current_time: completed_at)

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
      conflict_target: [ :id ], columns: [ :free_response, :answer_id ]
    }

    Tasks::Models::TaskStep.import task_steps, validate: false, on_duplicate_key_update: {
      conflict_target: [ :id ], columns: [ :first_completed_at, :last_completed_at ]
    }

    task.save!
    task.update_caches_now if update_caches

    role = task.taskings.first&.role
    course = role&.student&.course
    return if course.nil?

    queue = task.is_preview ? 'preview' : 'dashboard'
    run_at = task.feedback_available? ? Time.current : task.feedback_at

    book_part_uuids = Content::Models::Page
      .where(id: exercise_steps.map(&:content_page_id))
      .pluck(:parent_book_part_uuid, :uuid)
      .flatten
      .uniq
    book_part_uuids.each do |book_part_uuid|
      Cache::UpdateRoleBookPart.set(queue: queue, run_at: run_at).perform_later(
        role: role, book_part_uuid: book_part_uuid, queue: queue
      )
    end

    requests = tasked_exercises.map do |tasked_exercise|
      { course: course, tasked_exercise: tasked_exercise }
    end
    OpenStax::Biglearn::Api.record_responses requests
  end
end
