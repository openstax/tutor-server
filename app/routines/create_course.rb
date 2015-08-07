class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::Routines::CreateCourseProfile,
    translations: { outputs: { type: :verbatim } },
    as: :create_course_profile

  uses_routine SchoolDistrict::ProcessSchoolChange,
               as: :process_school_change

  def exec(name:, school: nil)
    # TODO eventually, making a course part of a school should be done independently
    # with separate admin controller interfaces and all work done in the SchoolDistrict
    # SS

    outputs[:course] = Entity::Course.create!
    run(:create_course_profile, name: name,
                                course: outputs.course,
                                school_district_school_id: school.try(:id))

    run(:process_school_change, course_profile: outputs.profile)
  end

end
