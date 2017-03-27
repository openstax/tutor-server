class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::CreateCourse, translations: { outputs: { type: :verbatim } },
                                            as: :create_course

  uses_routine CourseMembership::CreatePeriod, as: :create_period

  uses_routine SchoolDistrict::ProcessSchoolChange, as: :process_school_change

  uses_routine Tasks::CreateCourseAssistants, as: :create_course_assistants

  uses_routine AddEcosystemToCourse, as: :add_ecosystem

  uses_routine PopulatePreviewCourseContent, as: :populate_preview_course_content

  def exec(name:, term:, year:, is_preview:, is_college:, is_concept_coach: nil, num_sections: 0,
           catalog_offering: nil, appearance_code: nil, starts_at: nil, ends_at: nil,
           school: nil, time_zone: nil, cloned_from: nil,
           default_open_time: nil, default_due_time: nil)
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
    time_zone = time_zone.dup if time_zone.present? && time_zone.course.try!(:persisted?)

    run(:create_course,
        name: name,
        term: term,
        year: year,
        is_college: is_college,
        is_concept_coach: is_concept_coach,
        is_preview: is_preview,
        starts_at: starts_at,
        ends_at: ends_at,
        offering: catalog_offering.try!(:to_model),
        appearance_code: appearance_code,
        school: school,
        time_zone: time_zone,
        cloned_from: cloned_from,
        default_open_time: default_open_time,
        default_due_time: default_due_time)

    num_sections.times{ run(:create_period, course: outputs.course) }

    run(:create_course_assistants, course: outputs.course)

    run(:process_school_change, course: outputs.course)

    return if catalog_offering.blank?

    ecosystem = Content::Ecosystem.new(strategy: catalog_offering.ecosystem.to_model.wrap)

    run(:add_ecosystem, course: outputs.course, ecosystem: ecosystem)

    run(:populate_preview_course_content, course: outputs.course) if outputs.course.is_preview
  end

end
