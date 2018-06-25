class Research::AdmitStudentsToStudies

  lev_routine

  protected

  def exec(students:, studies:)
    students = [students].flatten
    studies = [studies].flatten

    studies.each do |study|
      students.each do |student|
        admit!(student, study) if qualifies?(student, study)
      end
    end
  end

  def qualifies?(student, study)
    # For now, researchers manually group courses into studies, and all of those
    # course's students "qualify" for the study.  Could change later based on
    # research team needs.
    true
  end

  def admit!(student, study)
    cohort_member = Research::Models::CohortMember.create(cohort: next_cohort_to_admit_to(study),
                                                          student: student)
    transfer_errors_from(cohort_member, {type: :verbatim}, true)

    # TODO assign_missing_surveys goes here? (and remove from CourseMembership::AddStudent)
  end

  def next_cohort_to_admit_to(study)
    # Uses a local cache of cohorts so we for sure get the same cohort objects
    # over and over, so the counter caches appear to be updated during the routine's
    # transaction

    # TODO really spec this!! fail review without spec

    @study_cohorts ||= {}
    all_cohorts = (@study_cohorts[study.id] ||= cohorts_with_default(study))
    target_cohort = all_cohorts.sort(&:cohort_members_count).first
  end

  def cohorts_with_default(study)
    # Return the study's cohorts, making sure there is at least one default cohort.

    cohorts = study.cohorts

    if cohorts.none?
      default_cohort = Research::Models::Cohort.create(name: "Default", study: study)
      transfer_errors_from(default_cohort, {type: :verbatim}, true)
      cohorts.push(default_cohort)
    end

    cohorts
  end
end
