class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::CreateCourseProfile,
               translations: { outputs: { type: :verbatim } },
               as: :create_course_profile

  uses_routine SchoolDistrict::ProcessSchoolChange,
               as: :process_school_change

  uses_routine Tasks::CreateCourseAssistants,
               as: :create_course_assistants

  def exec(name:, is_concept_coach:, is_college:, starts_at:, ends_at:,
           catalog_offering: nil, appearance_code: nil, school: nil, time_zone: nil)
    # TODO eventually, making a course part of a school should be done independently
    # with separate admin controller interfaces and all work done in the SchoolDistrict SS

    outputs[:course] = Entity::Course.create!
    run(:create_course_profile,
        course: outputs.course,
        name: name,
        is_concept_coach: is_concept_coach,
        is_college: is_college,
        starts_at: starts_at,
        ends_at: ends_at,
        offering: catalog_offering.try!(:to_model),
        appearance_code: appearance_code,
        school: school,
        time_zone: time_zone
        )

    run(:create_course_assistants, course: outputs.course)

    run(:process_school_change, course_profile: outputs.profile)
  end

end
