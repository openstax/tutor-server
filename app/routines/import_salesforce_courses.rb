class ImportSalesforceCourses
  lev_routine

  uses_routine CreateCourse
  uses_routine SchoolDistrict::GetSchool, as: :get_school
  uses_routine SchoolDistrict::CreateSchool, as: :create_school
  uses_routine CourseContent::AddEcosystemToCourse, as: :set_ecosystem
  uses_routine Salesforce::AttachRecord, as: :attach_record

  def initialize
    outputs.num_failures = 0
    outputs.num_successes = 0
  end

  def exec(include_real_salesforce_data: nil)
    @include_real_salesforce_data_preference = include_real_salesforce_data

    candidate_sf_records.each do |candidate|
      create_course_for_candidate(candidate)
      candidate.save_if_changed
    end
  end

  def include_real_salesforce_data?
    # The "include real" parameter to this routine is used if set; if not set,
    # fall back to the GlobalSettings value.  If that not set, don't import real.
    # In any event, only ever include real data if the secret setting say it is
    # allowed (JP doesn't trust admins, and wants this failsafe secret to let us
    # only use real SF data in the real real production site).

    (@include_real_salesforce_data_preference.present? ?
      @include_real_salesforce_data_preference :
      GlobalSettings.import_real_salesforce_courses || false) &&
    Rails.application.secrets['salesforce']['allow_use_of_real_data']
  end

  def candidate_sf_records
    search_criteria = {
      concept_coach_approved: true,
      course_id: nil
    }

    if !include_real_salesforce_data?
      search_criteria[:school] = 'Denver University'
      Rails.logger.info { "Starting Salesforce course import using test data only" }
    end

    Salesforce::Remote::ClassSize.where(search_criteria)
  end

  def create_course_for_candidate(candidate)
    offering = Catalog::Offering.find_by(salesforce_book_name: candidate.book_name)

    if offering.nil?
      error!(candidate, "Book Name does not match an offering in Tutor.")
      return
    end

    if !offering.is_concept_coach
      error!(candidate, "Book Name matches a Tutor offering but it isn't for CC.")
      return
    end

    candidate.course_name ||= offering.default_course_name

    if candidate.course_name.blank?
      error!(candidate, "A course name is needed and no default is available in Tutor.")
      return
    end

    school = run(:get_school, name: candidate.school).outputs.school ||
             run(:create_school, name: candidate.school).outputs.school

    course = run(
      :create_course,
      name: candidate.course_name,
      school: school,
      catalog_offering: offering,
      is_concept_coach: true
    ).outputs.course

    candidate.course_id = course.id
    candidate.created_at = course.created_at.iso8601
    candidate.num_students = 0
    candidate.num_teachers = 0
    candidate.num_sections = 0
    candidate.teacher_join_url = UrlGenerator.new.join_course_url(course.teacher_join_token)

    run(:set_ecosystem, course: course, ecosystem: offering.ecosystem)

    # Remember the candidate obj ID so we can write stats later
    run(:attach_record, record: candidate, to: course)

    Rails.logger.info {
      "Created course '#{course.name}' (#{course.id}) based on Salesforce record " +
      "#{candidate.id} using offering '#{offering.salesforce_book_name}' (#{offering.id}) " +
      "and ecosystem '#{offering.ecosystem.title}'."
    }

    success!(candidate)
  end

  def success!(candidate)
    candidate.error = nil
    outputs.num_successes += 1
  end

  def error!(candidate, message)
    candidate.error = message
    outputs.num_failures += 1
  end

end
