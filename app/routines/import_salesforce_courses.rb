class ImportSalesforceCourses
  lev_routine

  uses_routine CreateCourse
  uses_routine SchoolDistrict::GetSchool, as: :get_school
  uses_routine SchoolDistrict::CreateSchool, as: :create_school
  uses_routine CourseContent::AddEcosystemToCourse, as: :set_ecosystem

  def exec
    candidate_sf_records.each do |candidate|
      create_course_for_candidate(candidate)
      candidate.save if candidate.changed?
    end
  end

  def candidate_sf_records
    Salesforce::Remote::ClassSize.where(using_concept_coach: true, course_id: nil)
  end

  def create_course_for_candidate(candidate)
    offering = Catalog::Offering.find_by(identifier: candidate.offering_uid).first

    if offering.nil? || !offering.is_concept_coach
      candidate.error = "Book Name does not match a CC offering in Tutor."
      return
    end

    school = run(:get_school, name: candidate.school).outputs.school ||
             run(:create_school, name: candidate.school).outputs.school

    candidate.course_name ||= offering.default_course_name

    if candidate.course_name.blank?
      candidate.error = "A course name is needed and no default is available in Tutor."
      return
    end

    course = run(
      :create_course,
      name: candidate.course_name,
      school: school,
      catalog_offering: offering,
    ).outputs.course

    candidate.course_id = course.id
    candidate.created_at = course.created_at.iso8601
    candidate.num_students = 0
    candidate.num_teachers = 0
    # TODO set the teacher registration URL

    run(:set_ecosystem, course: course, ecosystem: offering.ecosystem)

    # Remember the candidate obj ID so we can write stats later
    Salesforce::Models::CourseClassSize.create!(course: course, class_size_id: candidate.id)

    # clear any existing error message
    candidate.error = nil
  end

end
