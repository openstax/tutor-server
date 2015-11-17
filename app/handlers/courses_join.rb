class CoursesJoin
  lev_handler

  uses_routine AddUserAsCourseTeacher, as: :add_teacher
  uses_routine GetCourseProfile

  protected
  def authorized?; true; end

  def handle
    after_transaction { cause_fatal_error if errors.any? }

    outputs.course = find_course_by_join_token
    run(:add_teacher, course: outputs.course, user: caller)
  end

  private
  def find_course_by_join_token
    profile = nil
    profile_attrs = { teacher_join_token: params[:join_token] }
    profile_routine = run(:get_course_profile, attrs: profile_attrs)

    if profile_routine.errors.any?
      fatal_error(code: :invalid_token, message: 'You are trying to join a class as a teacher, but the information you provided is either out of date or does not correspond to an existing course.')
    else
      profile = profile_routine.outputs.profile
    end

    Entity::Course.find_by(id: profile.course_id)
  end

  def cause_fatal_error
    fatal_error(code: :subroutine_errors, message: errors.first.message)
  end
end
