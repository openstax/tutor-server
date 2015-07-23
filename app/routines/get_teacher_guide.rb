class GetTeacherGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_course_stats(role.teacher.course)
  end

  private

  def completed_exercise_steps_for_period(period)
    filter_completed_exercise_steps(
      period.enrollments.latest.active.preload(
        student: {role: {taskings: {task: {task: {task_steps: {task: {taskings: :role}}}}}}}
      ).collect{ |en| en.student.role.taskings.collect{ |ts| ts.task.task.task_steps } }
       .flatten
    )
  end

  def gather_period_stats(period)
    task_steps = completed_exercise_steps_for_period(period)
    book = period.course.books.last
    { period_id: period.id }.merge(compile_guide(task_steps, book))
  end

  def gather_course_stats(course)
    course.periods.collect do |period|
      period_stats_per_book = gather_period_stats(period)
      # Assume only 1 book for now
      period_stats_per_book.first
    end
  end
end
