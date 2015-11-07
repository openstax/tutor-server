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

  def exec(run_on_test_data_only: true)
    @run_on_test_data_only = run_on_test_data_only

    candidate_sf_records.each do |candidate|
      create_course_for_candidate(candidate)
      candidate.save if candidate.changed?
    end
  end

  def candidate_sf_records
    search_criteria = {
      concept_coach_approved: true,
      course_id: nil
    }

    if @run_on_test_data_only
      search_criteria[:school] = 'Denver University'
      Rails.logger.info { "Starting Salesforce course import using test data only" }
    end

    Salesforce::Remote::ClassSize.where(search_criteria)
  end

  def create_course_for_candidate(candidate)
    assume_success(candidate)

    offering = Catalog::Offering.find_by(identifier: candidate.book_name).first

    if offering.nil?
      error(candidate, "Book Name does not match an offering in Tutor.")
      return
    end

    if !offering.is_concept_coach
      error(candidate, "Book Name matches a Tutor offering but it isn't for CC.")
      return
    end

    candidate.course_name ||= offering.default_course_name

    if candidate.course_name.blank?
      error(candidate, "A course name is needed and no default is available in Tutor.")
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
    candidate.teacher_join_url =
      UrlGenerator.new.access_course_url(access_token: course.teacher_access_token)

    run(:set_ecosystem, course: course, ecosystem: offering.ecosystem)

    # Remember the candidate obj ID so we can write stats later
    run(:attach_record, record: candidate, to: course)

    Rails.logger.info {
      "Created course '#{course.name}' (#{course.id}) based on Salesforce record " +
      "#{candidate.id} using offering '#{offering.identifier}' (#{offering.id}) " +
      "and ecosystem '#{offering.ecosystem.title}'."
    }
  end

  def assume_success(candidate)
    candidate.error = nil
    outputs.num_successes += 1
  end

  def error(candidate, message)
    candidate.error = message
    outputs.num_successes -= 1
    outputs.num_failures += 1
  end

end
