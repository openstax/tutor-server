class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::CreateCourseProfile,
               translations: { outputs: { type: :verbatim } },
               as: :create_course_profile

  uses_routine SchoolDistrict::ProcessSchoolChange,
               as: :process_school_change

  uses_routine Tasks::CreateCourseAssistants,
               as: :create_course_assistants

  uses_routine AddEcosystemToCourse,
               as: :add_ecosystem

  def exec(name:, term:, year:, is_college:, is_concept_coach: nil, catalog_offering: nil,
           appearance_code: nil, starts_at: nil, ends_at: nil, school: nil, time_zone: nil)
    # TODO eventually, making a course part of a school should be done independently
    # with separate admin controller interfaces and all work done in the SchoolDistrict SS

    is_concept_coach = catalog_offering.try!(:is_concept_coach) if is_concept_coach.nil?

    fatal_error(
      code: :is_concept_coach_blank,
      message: 'You must provide at least one of the following 2 options: ' +
               ':is_concept_coach or :catalog_offering'
    ) if is_concept_coach.nil?

    # If the given time_zone already has an associated course,
    # make a copy to avoid linking the 2 courses' time_zones to the same record
    time_zone = time_zone.dup if time_zone.present? && time_zone.profile.try!(:persisted?)

    outputs.course = Entity::Course.create!
    run(:create_course_profile,
        course: outputs.course,
        name: name,
        is_concept_coach: is_concept_coach,
        is_college: is_college,
        term: term,
        year: year,
        starts_at: starts_at,
        ends_at: ends_at,
        offering: catalog_offering.try!(:to_model),
        appearance_code: appearance_code,
        school: school,
        time_zone: time_zone)

    run(:create_course_assistants, course: outputs.course)

    run(:process_school_change, course_profile: outputs.profile)

    run(:add_ecosystem, course: outputs.course, ecosystem: catalog_offering.ecosystem) \
      if catalog_offering.present?
  end

end
