class CoursesJoin
  lev_handler uses: [GetCourseProfile, { name: AddUserAsCourseTeacher, as: :add_teacher }]

  protected
  def authorized?; true; end

  def handle
    after_transaction { raise_handled_exceptions! }

    profile = run(:get_course_profile, attrs: { teacher_join_token: params[:join_token] }).profile
    course = Entity::Course.find(profile.entity_course_id)
    run(:add_teacher, course: course, user: caller)
  end

  private
  def raise_handled_exceptions!
    raise self.class.handled_exceptions[errors.first.code] if errors.any?
  end

  def self.handled_exceptions
    @@handled_exceptions ||= {
      profile_not_found: InvalidTeacherJoinToken
    }
  end
end

class InvalidTeacherJoinToken < StandardError; end
