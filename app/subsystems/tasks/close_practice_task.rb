class Tasks::ClosePracticeTask
  lev_routine express_output: :task

  include Ratings::Concerns::RatingJobs

  protected

  def exec(id:, role:)
    task = ::Tasks::GetPracticeTask[
      id: id,
      role: role,
      task_type: ::Tasks::Models::Task::PRACTICE_TASK_TYPES
    ]
    return unless task

    task.close_and_make_due!

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
