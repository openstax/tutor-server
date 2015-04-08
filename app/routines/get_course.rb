class GetCourse
  lev_routine

  uses_routine CourseProfile::GetProfile,
    translations: { outputs: { map: { profile: :course } } },
    as: :get_profile

  protected

  def exec(entity_course_id)
    run(:get_profile, entity_course_id)
  end
end
