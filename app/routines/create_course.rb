class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::Routines::CreateCourseProfile,
               translations: { outputs: { type: :verbatim } },
               as: :create_course_profile

  uses_routine SchoolDistrict::ProcessSchoolChange,
               as: :process_school_change

  uses_routine Tasks::CreateCourseAssistants,
               as: :create_course_assistants

  def exec(name:, appearance_code: nil, school: nil,
           catalog_offering: nil, is_concept_coach: false, is_college: false,
           time_zone: nil)
    # TODO eventually, making a course part of a school should be done independently
    # with separate admin controller interfaces and all work done in the SchoolDistrict
    # SS

    outputs[:course] = Entity::Course.create!
    run(:create_course_profile,
        name: name,
        appearance_code: appearance_code,
        course: outputs.course,
        catalog_offering_id: catalog_offering.try(:id),
        school_district_school_id: school.try(:id),
        is_concept_coach: is_concept_coach,
        is_college: is_college,
        time_zone: time_zone)

    run(:create_course_assistants, course: outputs.course)

    run(:process_school_change, course_profile: outputs.profile)
  end

end
