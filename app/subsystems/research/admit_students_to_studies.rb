class Research::AdminStudentsToStudies

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
    # this might be moot if the researchers manually group courses into studies
  end

  def admit!(student, study)
    cohort_member = CohortMember.create(cohort: next_cohort_to_admit_to(study), student: student)
    transfer_errors_from(cohort_member, {type: :verbatim}, true)
  end

  def next_cohort_to_admit_to(study)
    # keep a local cache of cohorts so we for sure get the same cohort objects
    # over and over, so the counter caches appear to be updated during the routine's
    # transaction

    # TODO really spec this!! fail review without spec

    @study_cohorts ||= {}
    all_cohorts = (@study_cohorts[study.id] ||= study.cohorts)
    target_cohort = all_cohorts.sort(&:cohort_members_count).first
  end
end
