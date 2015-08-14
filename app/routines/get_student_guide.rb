class GetStudentGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_role_stats(role)
  end

  private

  def task_steps_for_role(role)
    role.taskings.eager_load(task: {task: :task_steps})
        .collect{ |tasking| tasking.task.task.task_steps }.flatten
  end

  def gather_role_stats(role)
    task_steps = task_steps_for_role(role)
    period = role.student.period
    course = role.student.course
    { period_id: period.id }.merge(compile_course_guide(task_steps, course))
  end
end
