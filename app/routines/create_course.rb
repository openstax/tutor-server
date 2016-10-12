class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::CreateCourseProfile,
               translations: { outputs: { type: :verbatim } },
               as: :create_course_profile

  uses_routine SchoolDistrict::ProcessSchoolChange,
               as: :process_school_change

  uses_routine Tasks::CreateCourseAssistants,
               as: :create_course_assistants

  def exec(name:, catalog_offering: nil, appearance_code: nil, school: nil,
           is_concept_coach:, is_college:, time_zone: nil, starts_at:, ends_at:)
    # TODO eventually, making a course part of a school should be done independently
    # with separate admin controller interfaces and all work done in the SchoolDistrict SS

    outputs[:course] = Entity::Course.create!
    run(:create_course_profile,
        course: outputs.course,
        name: name,
        offering: catalog_offering.try!(:to_model),
        appearance_code: appearance_code,
        school: school,
        is_concept_coach: is_concept_coach,
        is_college: is_college,
        time_zone: time_zone,
        starts_at: starts_at,
        ends_at: ends_at)

    run(:create_course_assistants, course: outputs.course)

    run(:process_school_change, course_profile: outputs.profile)
  end

end
