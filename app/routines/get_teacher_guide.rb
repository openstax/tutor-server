class GetTeacherGuide

  include CourseGuideMethods

  lev_routine express_output: :course_guide

  protected

  def exec(role:)
    outputs.course_guide = gather_course_stats(role.teacher.course)
  end

  private

  def completed_exercise_task_steps_for_course_by_period(course)
    course.periods.each_with_object({}) do | period, hash |
      hash[period.id] = Tasks::Models::TaskStep.exercises.complete
        .preload([
          {tasked: :exercise},
          {task: {taskings: {role: {student: {enrollments: :period}}}}}
        ]).joins(
          task: {taskings: {role: {student: :enrollments}}}
        ).where(
          task: {taskings: {role: {student: {enrollments: {
            course_membership_period_id: period.id
          }}}}}
        ).joins{CourseMembership::Models::Enrollment.unscoped.as(:newer_enrollment).on{
          (newer_enrollment.course_membership_student_id == ~task.taskings.role.student.enrollments.course_membership_student_id) & \
          (newer_enrollment.created_at > ~task.taskings.role.student.enrollments.created_at)
        }.outer}.where(newer_enrollment: {id: nil}).to_a
    end
  end

  def gather_period_stats(period_id, course, tasked_exercises, exercise_id_to_page_map)
    { period_id: period_id }.merge(
      compile_course_guide(course, tasked_exercises, exercise_id_to_page_map, :teacher)
    )
  end

  def gather_course_stats(course)

    period_to_completed_exercise_task_steps_map = \
      completed_exercise_task_steps_for_course_by_period(course)

    all_completed_exercise_task_steps = period_to_completed_exercise_task_steps_map.values.flatten

    task_step_to_tasked_exercise_map = \
      all_completed_exercise_task_steps.map(&:tasked).group_by{ |te| te.task_step.id }

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
