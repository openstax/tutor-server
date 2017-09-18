class CourseProfile::CreateCourse
  lev_routine

  protected
  def exec(attrs = {})
    attrs[:is_lms_enabling_allowed] = Settings::Db.store.default_is_lms_enabling_allowed
    attrs[:is_lms_enabled] = nil

    outputs.course = CourseProfile::Models::Course.create(attrs)
    transfer_errors_from outputs.course, {type: :verbatim}, true
  end
end
