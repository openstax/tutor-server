class GetStudentGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_role_stats(role)
  end

  private

  def completed_task_steps_for_role(role)
    role.taskings.eager_load(task: {task: {task_steps: {task: {taskings: :role}}}})
        .collect{ |tasking| tasking.task.task.task_steps }
        .flatten.select(&:completed?)
  end

  def gather_role_stats(role)
    task_steps = completed_task_steps_for_role(role)
    period = role.student.period
    role_stats_per_book = compile_books(task_steps).collect do |book_stats|
      { period_id: period.id }.merge(book_stats)
    end
    # Assume only 1 book for now
    role_stats_per_book.first
  end
end
