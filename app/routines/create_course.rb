class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::Routines::CreateCourseProfile,
    translations: { outputs: { type: :verbatim } },
    as: :create_course_profile

  def exec(name: 'Unnamed', school_id: nil)
    outputs[:course] = Entity::Course.create!
    run(:create_course_profile, name: name,
                                course: outputs.course,
                                course_detail_school_id: school_id)
  end
end
