class GetTeacherGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_course_stats(role.teacher.course)
  end

  private

  def task_steps_for_period(period)
    period.enrollments.latest.active.eager_load(
      student: {role: {taskings: {task: {task: :task_steps}}}}
    ).collect{ |en| en.student.role.taskings.collect{ |ts| ts.task.task.task_steps } }.flatten
  end

  def gather_period_stats(period, course)
    task_steps = task_steps_for_period(period)
    { period_id: period.id }.merge(compile_course_guide(task_steps, course))
  end

  def gather_course_stats(course)
    course.periods.collect{ |period| gather_period_stats(period, course) }
  end
end
