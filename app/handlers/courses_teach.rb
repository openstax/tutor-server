class CoursesTeach
  class InvalidTeachToken < StandardError
  end

  class UserIsStudent < StandardError
  end

  lev_handler

  uses_routine UserIsCourseStudent,    as: :user_is_course_student
  uses_routine AddUserAsCourseTeacher, as: :add_teacher,
                                       translations: { outputs: { type: :verbatim } },
                                       ignored_errors: [:user_is_already_a_course_teacher]

  protected

  def authorized?
    true
  end

  def handle
    course = CourseProfile::Models::Course.find_by(teach_token: params[:teach_token])
    outputs.course = course
    raise InvalidTeachToken if course.nil?
    raise UserIsStudent if run(
      :user_is_course_student,
      user: caller, course: course, include_dropped_students: true, include_archived_periods: true
    ).outputs.is_course_student

    run(:add_teacher, course: course, user: caller)
  end
end
