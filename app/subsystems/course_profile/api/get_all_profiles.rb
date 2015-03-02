class CourseProfile::Api::GetAllProfiles
  lev_routine

  protected

  def exec
    outputs[:profiles] = CourseProfile::Profile.all.collect do |profile|
      {
        course_id: profile.entity_course_id,
        name: profile.name
      }
    end
  end
end