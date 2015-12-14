class CreateCourse
  lev_routine outputs: {
    course: :_self,
    _verbatim: { name: CourseProfile::Routines::CreateCourseProfile,
                 as: :create_course_profile }
  },
  uses: [
    { name: SchoolDistrict::ProcessSchoolChange, as: :process_school_change },
    { name: Tasks::CreateCourseAssistants, as: :create_course_assistants }
  ]

  protected
  def exec(name:, appearance_code: nil, school: nil,
           catalog_offering: nil, is_concept_coach: false)
    # TODO eventually, making a course part of a school should be done independently
    # with separate admin controller interfaces and all work done in the SchoolDistrict
    # SS

    set(course: Entity::Course.create!)

    run(:create_course_profile, name: name,
                                appearance_code: appearance_code,
                                course: result.course,
                                catalog_offering_id: catalog_offering.try(:id),
                                school_district_school_id: school.try(:id),
                                is_concept_coach: is_concept_coach)

    run(:create_course_assistants, course: result.course)
    run(:process_school_change, course_profile: result.profile)
  end
end
