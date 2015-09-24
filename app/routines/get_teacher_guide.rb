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

  def gather_period_stats(period_id, course, tasked_exercises, exercise_id_to_page_map)
    { period_id: period_id }.merge(
      compile_course_guide(course, tasked_exercises, exercise_id_to_page_map)
    )
  end

  def gather_course_stats(course)
    period_to_completed_exercise_task_steps_map = \
      completed_exercise_task_steps_for_course_by_period(course)

    all_completed_exercise_task_steps = period_to_completed_exercise_task_steps_map.values.flatten

    task_step_to_tasked_exercise_map = get_tasked_exercises_from_completed_exercise_task_steps(
      all_completed_exercise_task_steps
    )

    all_tasked_exercises = task_step_to_tasked_exercise_map.values.flatten

    exercise_id_to_page_map = map_tasked_exercise_exercise_ids_to_latest_pages(
      all_tasked_exercises, course
    )

    course.periods.collect do |period|
      period_id = period.id
      completed_exercise_task_steps = period_to_completed_exercise_task_steps_map[period_id]
      tasked_exercises = completed_exercise_task_steps.flat_map do |ts|
        task_step_to_tasked_exercise_map[ts.id]
      end
      gather_period_stats(period_id, course, tasked_exercises, exercise_id_to_page_map)
    end
  end
end
