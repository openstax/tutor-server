class MarkTaskStepCompleted
  lev_routine transaction: :read_committed

  uses_routine Tasks::PopulatePlaceholderSteps, as: :populate_placeholders

  protected

  def exec(task_step:, completed_at: Time.current, lock_task: true, save: true)
    task = task_step.task
    if lock_task && task.persisted?
      task.save!
      task.lock!
    end

    task_step.complete completed_at: completed_at
    transfer_errors_from task_step, { type: :verbatim }, true

    return unless errors.empty?

    if save
      task_step.save!
      task.save!
    end

    run(:populate_placeholders, task: task, lock_task: false) if task.core_task_steps_completed?

    return unless save && task_step.exercise?

    role = task.taskings.first&.role
    course = role&.student&.course
    return if course.nil?

    queue = task.is_preview ? 'preview' : 'dashboard'
    run_at = task.feedback_available? ? completed_at : task.feedback_at

    book_part_uuids = Content::Models::Page
      .where(id: task_step.content_page_id)
      .pluck(:parent_book_part_uuid, :uuid)
    book_part_uuids.each do |book_part_uuid|
      Cache::UpdateRoleBookPart.set(queue: queue, run_at: run_at).perform_later(
        role: role, book_part_uuid: book_part_uuid, queue: queue
      )
    end

    OpenStax::Biglearn::Api.record_responses course: course, tasked_exercise: task_step.tasked
  end
end
