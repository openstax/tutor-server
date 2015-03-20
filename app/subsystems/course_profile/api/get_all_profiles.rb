class CourseProfile::Api::GetAllProfiles
  lev_routine

  protected

  def exec
    outputs[:profiles] = CourseProfile::Profile.all.collect do |profile|
      {
        id: profile.entity_course_id,
        name: profile.name
      }
    end
  end
end
