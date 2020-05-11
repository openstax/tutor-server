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
    period = role&.course_member&.period
    course = period&.course
    # course will only be set if role and period were found
    return if course.nil?

    queue = task.preview_course? ? 'preview' : 'dashboard'
    role_run_at = task.auto_grading_feedback_available? ? completed_at :
                                                          [ task.due_at, completed_at ].compact.max

    page = Content::Models::Page
      .select(:uuid, :parent_book_part_uuid)
      .find_by(id: task_step.content_page_id)

    if task.completed?(use_cache: true)
      page_uuid_book_part_uuids = Content::Models::Page.where(
        id: task.task_steps.map(&:content_page_id).uniq
      ).pluck(:uuid, :parent_book_part_uuid)
      page_uuids = page_uuid_book_part_uuids.map(&:first)
      parent_book_part_uuids = page_uuid_book_part_uuids.map(&:second).uniq

      Ratings::UpdateRoleBookParts.set(queue: queue, run_at: role_run_at).perform_later(
        role: role, task: task, is_page: true
      )

      Ratings::UpdatePeriodBookParts.set(queue: queue).perform_later(
        period: period, task: task, is_page: true
      ) if role.student?
    end

    OpenStax::Biglearn::Api.record_responses course: course, tasked_exercise: task_step.tasked
  end
end
