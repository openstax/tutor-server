class Domain::ListCourses
  lev_routine

  uses_routine CourseProfile::Api::GetAllProfiles,
               translations: { outputs: { map: { profiles: :courses } } },
               as: :get_profiles
  uses_routine Domain::GetTeacherNames,
               translations: { outputs: { type: :verbatim } },
               as: :get_teacher_names

  protected

  def exec
    run(:get_profiles)
    outputs.courses.each do |course|
      teacher_names = run(:get_teacher_names, course.course_id).outputs.teacher_names
      course.teacher_names = teacher_names
    end
  end
end
