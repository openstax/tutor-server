class GetStudentGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_role_stats(role)
  end

  private

  def completed_exercise_steps_for_role(role)
    filter_completed_exercise_steps(
      role.taskings.eager_load(task: {task: {task_steps: {task: {taskings: :role}}}})
          .collect{ |tasking| tasking.task.task.task_steps }
          .flatten
    )
  end

  def gather_role_stats(role)
    task_steps = completed_exercise_steps_for_role(role)
    period = role.student.period
    book = role.student.course.books.last
    { period_id: period.id }.merge(compile_guide(task_steps, book))
  end
end
