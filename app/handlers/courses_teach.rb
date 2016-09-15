class CoursesTeach

  class InvalidTeachToken < StandardError; end

  lev_handler

  uses_routine GetCourseProfile, translations: { outputs: { type: :verbatim } }
  uses_routine AddUserAsCourseTeacher, as: :add_teacher,
                                       translations: { outputs: { type: :verbatim } },
                                       ignored_errors: [:user_is_already_teacher_of_course]

  protected

  def authorized?; true; end

  def handle
    after_transaction { raise_handled_exceptions! }

    run(:get_course_profile, attrs: { teach_token: params[:teach_token] })
    outputs.course = Entity::Course.find(outputs.profile.entity_course_id)
    run(:add_teacher, course: outputs.course, user: caller)
  end

  private

  def raise_handled_exceptions!
    raise InvalidTeachToken if errors.any?{ |err| err.code == :profile_not_found }
  end

end
