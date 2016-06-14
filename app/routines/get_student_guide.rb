class GetStudentGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_role_stats(role)
  end

  private

  def get_completed_tasked_exercises_for_role(role)
    role.taskings.preload(task: {tasked_exercises: [
      {task_step: {task: {taskings: {role: :profile}}}}, :exercise
    ]}).flat_map{ |tg| tg.task.tasked_exercises }.select{ |te| te.task_step.completed? }
  end

  def gather_role_stats(role)
    period = role.student.period
    course = role.student.course

    completed_tasked_exercises = get_completed_tasked_exercises_for_role(role)
    exercise_id_to_page_map = map_tasked_exercise_exercise_ids_to_latest_pages(
      completed_tasked_exercises, course
    )

    { period_id: period.id }
      .merge compile_course_guide(course, completed_tasked_exercises, exercise_id_to_page_map)
  end
end
