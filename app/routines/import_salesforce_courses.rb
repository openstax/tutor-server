class ImportSalesforceCourses
  lev_routine

  uses_routine CreateCourse

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

    candidate.course_name ||= offering.default_course_name

    if candidate.course_name.blank?
      candidate.error = "A course name is needed and no default is available in Tutor."
      return
    end

    course = run(:create_course, name: candidate.course_name).outputs.course

    candidate.course_id = course.id
    candidate.created_at = course.created_at.iso8601
    candidate.num_students = 0
    candidate.num_teachers = 0

    # TODO set the ecosystem
    # TODO set the SF ID so we can write back again later (store in SF SS)

    # clear any existing error message
    candidate.error = nil
  end

end
