class ImportSalesforceCourse
  lev_routine

  uses_routine CreateCourse, translations: { outputs: {type: :verbatim} }
  uses_routine SchoolDistrict::GetSchool, as: :get_school
  uses_routine SchoolDistrict::CreateSchool, as: :create_school
  uses_routine Salesforce::AttachRecord, as: :attach_record

  # Candidate can be `OsAncillary` or `ClassSize`
  def exec(candidate:, log_prefix: nil)
    @log_prefix = log_prefix

    offering = Catalog::Offering.find_by(salesforce_book_name: candidate.book_name)

    if offering.nil?
      error!(candidate, "Book Name does not match an offering in Tutor.")
      return
    end

    if !candidate.valid_product?
      error!(candidate, "Status is approved but 'Product' is missing or has an unexpected value.")
      return
    end

    if candidate.is_tutor? && !offering.is_tutor
      error!(candidate, "Book Name matches an offering in Tutor but not for full Tutor courses.")
      return
    end

    if candidate.is_concept_coach? && !offering.is_concept_coach
      error!(candidate, "Book Name matches an offering in Tutor but not for Concept Coach courses.")
      return
    end

    candidate.course_name ||= offering.default_course_name

    if candidate.course_name.blank?
      error!(candidate, "A course name is needed and no default is available in Tutor.")
      return
    end

    if candidate.school.blank?
      error!(candidate, "A school is required.")
      return
    end

    term_year = candidate.term_year_object

    if term_year.blank?
      error!(candidate, "A term_year is required.")
      return
    end

    school = run(:get_school, name: candidate.school, district: nil).outputs.school ||
             run(:create_school, name: candidate.school).outputs.school

    course = run(
      :create_course,
      name: candidate.course_name,
      term: term_year.term,
      year: term_year.start_year,
      starts_at: candidate.try(:course_start_date),
      school: school,
      catalog_offering: offering,
      is_preview: false,
      is_concept_coach: candidate.is_concept_coach?,
      is_college: candidate.is_college?
    ).outputs.course

    candidate.course_id = course.id
    candidate.created_at = course.created_at.iso8601
    candidate.reset_stats
    candidate.teacher_join_url = UrlGenerator.teach_course_url(course.teach_token)

    # Remember the candidate obj ID so we can write stats later
    run(:attach_record, record: candidate, to: course)

    log {
      "Created course '#{course.name}' (#{course.id}) based on Salesforce record " +
      "#{candidate.id} using offering '#{offering.salesforce_book_name}' (#{offering.id}) " +
      "and ecosystem '#{offering.ecosystem.title}'."
    }

    success!(candidate)
  end

  def success!(candidate)
    candidate.error = nil
  end

  def error!(candidate, message)
    candidate.error = message
    log { "Error! candidate: #{candidate.id}; message: #{message}." }
  end

  def log(&block)
    @log_prefix.present? ?
      Rails.logger.info { "[#{@log_prefix}] #{block.call}" } :
      Rails.logger.info { block.call }
  end

end
