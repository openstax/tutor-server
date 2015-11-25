class CourseMembership::IsConceptCoachTaskTeacher
  lev_routine express_output: :is_course_teacher

  uses_routine UserIsCourseTeacher, as: :user_is_course_teacher,
               translations: { outputs: { map: { user_is_course_teacher: :is_course_teacher } } }


  protected

  def exec(task:, user: )
    unless task.concept_coach?
      outputs[:is_course_teacher] = false
      return
    end
    course = task.concept_coach_task.task.taskings.first.try(:period).try(:course)
    run(:user_is_course_teacher, user: user, course: course) if course
  end
end
