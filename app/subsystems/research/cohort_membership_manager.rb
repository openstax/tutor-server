class Research::CohortMembershipManager

  class NoCohortsAvailable < StandardError; end
  class StudyHasBeenActive < StandardError; end
  class StudentAlreadyInStudy < StandardError; end

  def reassign_cohort_members(cohort)
    raise StudyHasBeenActive if @study.ever_active?

    cohort.cohort_members.each do |cohort_member|
      new_cohort = next_cohort_to_admit_to(excluding: cohort)
      raise NoCohortsAvailable if new_cohort.nil?
      new_cohort.cohort_members << cohort_member
      new_cohort.cohort_members_count += 1 # just temporary while looping gets reset below
    end

    @study.cohorts.each do |cohort|
      Research::Models::Cohort.reset_counters(cohort.id, :cohort_members)
    end
  end

  def add_student_to_a_cohort(student)
    if Research::Models::CohortMember.where(student: student, cohort: candidate_cohorts).any?
      raise StudentAlreadyInStudy
    end

    Research::Models::CohortMember.create(cohort: next_cohort_to_admit_to, student: student)
  end

  def remove_students_from_cohorts(students)
    cohort_members = Research::Models::CohortMember.where(course_membership_student_id: students.map(&:id))
    cohort_members.destroy_all
  end

  protected

  def initialize(study)
    @study = study
  end

  def next_cohort_to_admit_to(excluding: [])
    candidate_cohorts(excluding: excluding).sort_by(&:cohort_members_count).first
  end

  def candidate_cohorts(excluding: [])
    # Uses a local cache of cohorts so we for sure get the same cohort objects
    # over and over, so the counter caches appear to be updated during the routine's
    # transaction

    @candidate_cohorts ||= {}
    @candidate_cohorts[excluding] ||= begin
      open_cohorts_with_default - [excluding].flatten
    end
  end

  def open_cohorts_with_default
    # Return the study's open cohorts, making sure there is at least one default cohort.

    cohorts = @study.cohorts.accepting_members.to_a

    cohorts << Research::Models::Cohort.create!(name: "Default", study: @study) if cohorts.empty?

    cohorts
  end

end
