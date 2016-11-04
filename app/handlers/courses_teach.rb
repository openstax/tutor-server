class CoursesTeach

  class InvalidTeachToken < StandardError
  end

  lev_handler

  uses_routine AddUserAsCourseTeacher, as: :add_teacher,
                                       translations: { outputs: { type: :verbatim } },
                                       ignored_errors: [:user_is_already_teacher_of_course]

  protected

  def authorized?
    true
  end

  def handle
    outputs.course = CourseProfile::Models::Course.find_by(teach_token: params[:teach_token])
    raise InvalidTeachToken if outputs.course.nil?

    run(:add_teacher, course: outputs.course, user: caller)
  end

end
