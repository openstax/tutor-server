class ImportSalesforceCourses
  lev_routine

  uses_routine CreateCourse

  def exec
    candidate_sf_records.each do |candidate|
      offering = Catalog::Offering.find_by(identifier: candidate.offering_uid)

      if offering.blank?
        candidate.error = "Book Name does not match an offering in Tutor."
      else
        # Create a course, setting:
        #   the ecosystem
        #   the SF Id so we can write back again later (store in SF SS)

        course_name = candidate.course_name || 'TODO: REPLACE WITH OFFERING DEFAULT'
        course = run(:create_course, name: course_name).outputs.course

        # Write back to SF:
        #   the course ID
        #   the teacher registration URL
        #   0 students, 0 teachers

        candidate.course_id = course.id
        candidate.num_students = 0
        candidate.num_teachers = 0
      end

      candidate.save if candidate.changed?
    end
  end

  def candidate_sf_records
    Salesforce::Remote::ClassSize.where(using_concept_coach: true, course_id: nil)
  end

end
