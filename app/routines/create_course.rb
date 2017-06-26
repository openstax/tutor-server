class CreateCourse
  lev_routine express_output: :course

  uses_routine CourseProfile::CreateCourse, translations: { outputs: { type: :verbatim } },
                                            as: :create_course

  uses_routine CourseMembership::CreatePeriod, as: :create_period


  uses_routine SchoolDistrict::ProcessSchoolChange, as: :process_school_change

  uses_routine Tasks::CreateCourseAssistants, as: :create_course_assistants

  uses_routine AddEcosystemToCourse, as: :add_ecosystem
  uses_routine CourseProfile::ClaimPreviewCourse, as: :claim_preview_course,
                                                  translations: { outputs: { type: :verbatim } }

  def exec(name:, is_preview:, is_college:, is_test: false, is_concept_coach: nil,
           term: nil, year: nil, num_sections: 0, catalog_offering: nil, appearance_code: nil,
           starts_at: nil, ends_at: nil, school: nil, time_zone: nil, cloned_from: nil,
           default_open_time: nil, default_due_time: nil, estimated_student_count: nil,
           does_cost: nil)

    # TODO eventually, making a course part of a school should be done independently
    # with separate admin controller interfaces and all work done in the SchoolDistrict SS

    if is_preview
      term = :preview
      year = Time.current.year
    else
      fatal_error(
        code: :term_year_blank,
        message: 'You must specify the course term and year (except for preview courses)'
      ) if term.blank? || year.blank?
    end

    is_concept_coach = catalog_offering.try!(:is_concept_coach) if is_concept_coach.nil?
    does_cost = (catalog_offering.try!(:does_cost) || false) if does_cost.nil?

    fatal_error(
      code: :is_concept_coach_blank,
      message: 'You must provide at least one of the following 2 options: ' +
               ':is_concept_coach or :catalog_offering'
    ) if is_concept_coach.nil?

    # Convert time_zone to a model
    # if it already is and has an associated course,
    #   make a copy to avoid linking the 2 courses' time_zones to the same record
    if time_zone.present?
      if time_zone.is_a?(TimeZone)
        time_zone = time_zone.dup if time_zone.course.try!(:persisted?)
      else
        time_zone = TimeZone.new(name: time_zone)
      end
    end

    run(
      :create_course,
      name: name,
      is_college: is_college,
      is_concept_coach: is_concept_coach,
      is_test: is_test,
      is_preview: is_preview,
      does_cost: does_cost,
      term: term,
      year: year,
      starts_at: starts_at,
      ends_at: ends_at,
      offering: catalog_offering.try!(:to_model),
      appearance_code: appearance_code,
      school: school,
      time_zone: time_zone,
      cloned_from: cloned_from,
      default_open_time: default_open_time,
      default_due_time: default_due_time,
      estimated_student_count: estimated_student_count,
      biglearn_student_clues_algorithm_name: Settings::Biglearn.student_clues_algorithm_name,
      biglearn_teacher_clues_algorithm_name: Settings::Biglearn.teacher_clues_algorithm_name,
      biglearn_assignment_spes_algorithm_name: Settings::Biglearn.assignment_spes_algorithm_name,
      biglearn_assignment_pes_algorithm_name: Settings::Biglearn.assignment_pes_algorithm_name,
      biglearn_practice_worst_areas_algorithm_name: \
        Settings::Biglearn.practice_worst_areas_algorithm_name
    )

    unless catalog_offering.blank?
      ecosystem = Content::Ecosystem.new(strategy: catalog_offering.ecosystem.to_model.wrap)

      run(:add_ecosystem, course: outputs.course, ecosystem: ecosystem)
    end

    num_sections.times{ run(:create_period, course: outputs.course) }

    run(:create_course_assistants, course: outputs.course)

    run(:process_school_change, course: outputs.course)
  end

end
