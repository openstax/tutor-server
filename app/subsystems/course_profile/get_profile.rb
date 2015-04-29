class CourseProfile::GetProfile
  lev_routine express_output: :profile

  protected

  def exec(course:)
    profile = CourseProfile::Models::Profile.find_by(entity_course_id: course.id)
    outputs[:profile] = {
      course_id: course.id,
      name: profile.name
    }
  end
end
