class GetTeacherGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_course_stats(role.teacher.course)
  end

  private

  def completed_exercise_task_steps_for_course_by_period(course)
    course.periods.preload(
      active_enrollments: {student: {role: {taskings: {task: {task: :task_steps}}}}}
    ).to_a.each_with_object({}) do |period, hash|
      hash[period.id] = get_completed_exercise_task_steps(
        period.active_enrollments.flat_map do |ae|
          ae.student.role.taskings.flat_map{ |ts| ts.task.task.task_steps }
        end
      )
    end
  end

  def gather_period_stats(tasked_exercises, period_id, course)
    { period_id: period_id }.merge(compile_course_guide(tasked_exercises, course))
  end

  def gather_course_stats(course)
    completed_exercise_task_steps_map = completed_exercise_task_steps_for_course_by_period(course)
    tasked_exercises_map = get_tasked_exercises_map_from_completed_exercise_task_steps(
      completed_exercise_task_steps_map.values.flatten
    )

    course.periods.collect do |period|
      period_id = period.id
      completed_exercise_task_steps = completed_exercise_task_steps_map[period_id]
      tasked_exercises = completed_exercise_task_steps.flat_map do |ts|
        tasked_exercises_map[ts.id]
      end
      gather_period_stats(tasked_exercises, period_id, course)
    end
  end
end
