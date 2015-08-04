class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::Routines::CreateCourseProfile,
    translations: { outputs: { type: :verbatim } },
    as: :create_course_profile

  def exec(name:, school: nil)
    school ||= NoSchool.new
    outputs[:course] = Entity::Course.create!
    run(:create_course_profile, name: name,
                                course: outputs.course,
                                school_district_school_id: school.id)
  end

  class NoSchool
    def id; end
  end
end
