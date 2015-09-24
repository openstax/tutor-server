class GetStudentGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_role_stats(role)
  end

  private

  def completed_exercise_task_steps_for_role(role)
    get_completed_exercise_task_steps(
      role.taskings
        .preload(task: {task: :task_steps})
        .flat_map{ |tasking| tasking.task.task.task_steps }
    )
  end

  def gather_role_stats(role)
    period = role.student.period
    course = role.student.course

    completed_exercise_task_steps = completed_exercise_task_steps_for_role(role)
    tasked_exercises = get_tasked_exercises_from_completed_exercise_task_steps(
      completed_exercise_task_steps
    ).values.flatten
    exercise_id_to_page_map = map_tasked_exercise_exercise_ids_to_latest_pages(
      tasked_exercises, course
    )

    { period_id: period.id }.merge(
      compile_course_guide(course, tasked_exercises, exercise_id_to_page_map)
    )
  end
end
