class CourseProfile::GetAllProfiles
  lev_routine

  protected

  def exec
    outputs[:profiles] = CourseProfile::Models::Profile.all.collect do |profile|
      {
        id: profile.entity_course_id,
        name: profile.name
      }
    end
  end
end
