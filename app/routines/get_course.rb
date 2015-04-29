class GetCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::GetProfile,
    translations: { outputs: { map: { profile: :course } } },
    as: :get_profile

  protected

  def exec(course:)
    run(:get_profile, course: course)
  end
end
