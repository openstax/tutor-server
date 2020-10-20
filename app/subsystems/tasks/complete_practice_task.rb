class Tasks::CompletePracticeTask
  lev_routine express_output: :task

  include Ratings::Concerns::RatingJobs

  protected

  def exec(id:, role:)
    task = ::Tasks::GetPracticeTask[
      id: id,
      role: role,
      task_type: ::Tasks::Models::Task::PRACTICE_TASK_TYPES
    ]
    return unless task && task.practice?

    task.task_steps.reject(&:completed?).map(&:delete)
    task.task_steps.reload
    task.due_at = Time.current
    task.closes_at = Time.current
    task.save!

    period = role&.course_member&.period

    perform_rating_jobs_later(
      task: task,
      role: role,
      period: period,
      event: :work,
      lock_task: false
    )

    outputs.task = task
  end
end
