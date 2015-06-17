class CourseProfile::GetAllProfiles
  lev_routine

  protected

  def exec(user: nil)
    profiles = CourseProfile::Models::Profile.all
    filtered = if user
                 profiles.select { |p| UserIsCourseStudent[user: user,
                                                           course: p.course] }
               else
                 profiles
               end

    outputs[:profiles] = profiles.collect do |profile|
                           { id: profile.entity_course_id,
                             name: profile.name }
                         end
  end
end
