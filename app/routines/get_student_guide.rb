class GetStudentGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_role_stats(role)
  end

  private

  def get_completed_exercise_task_steps(task_steps)
    task_steps.select{ |ts| ts.exercise? && ts.completed? }
  end

  def completed_exercise_task_steps_for_role(role)
    get_completed_exercise_task_steps(
      role.taskings
        .preload(task: :task_steps)
        .flat_map{ |tg| tg.task.task_steps }
    )
  end

  def get_tasked_exercises_from_completed_exercise_task_steps(completed_exercise_task_steps)
    tasked_exercise_ids = completed_exercise_task_steps.map(&:tasked_id)
    Tasks::Models::TaskedExercise.where(id: tasked_exercise_ids).preload(
      [{task_step: {task: {taskings: {role: :profile}}}}, :exercise]
    ).to_a.group_by{ |te| te.task_step.id }
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
