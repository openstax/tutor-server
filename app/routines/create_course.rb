class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::CreateCourseProfile,
               translations: { outputs: { type: :verbatim } },
               as: :create_course_profile

  uses_routine SchoolDistrict::ProcessSchoolChange,
               as: :process_school_change

  uses_routine Tasks::CreateCourseAssistants,
               as: :create_course_assistants

  def exec(name:, term:, year:, is_college:, catalog_offering:, is_concept_coach: nil,
           appearance_code: nil, starts_at: nil, ends_at: nil, school: nil, time_zone: nil)
    # TODO eventually, making a course part of a school should be done independently
    # with separate admin controller interfaces and all work done in the SchoolDistrict SS

    fatal_error(code: :no_catalog_offering, message: 'A catalog offering must be provided') \
      if catalog_offering.nil?

    # If the given time_zone already has an associated course,
    # make a copy to avoid linking the 2 courses' time_zones to the same record
    time_zone = time_zone.dup if time_zone.present? && time_zone.profile.try!(:persisted?)

    outputs.course = Entity::Course.create!
    run(:create_course_profile,
        course: outputs.course,
        name: name,
        is_concept_coach: is_concept_coach || catalog_offering.is_concept_coach,
        is_college: is_college,
        term: term,
        year: year,
        starts_at: starts_at,
        ends_at: ends_at,
        offering: catalog_offering.to_model,
        appearance_code: appearance_code,
        school: school,
        time_zone: time_zone)

    run(:create_course_assistants, course: outputs.course)

    run(:process_school_change, course_profile: outputs.profile)
  end

end
