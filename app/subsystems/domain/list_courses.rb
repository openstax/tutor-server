class Domain::ListCourses
  lev_routine

  uses_routine CourseProfile::Api::GetAllProfiles,
               translations: { outputs: { type: :verbatim } },
               as: :get_profiles

  protected

  def exec
    run(:get_profiles)
  end
end