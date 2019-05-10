class Research::AdmitStudentsToStudies

  lev_routine

  uses_routine Research::AssignMissingSurveys, as: :assign_missing_surveys,
                                               translations: { outputs: { type: :verbatim } }

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
    add_student_to_a_cohort(student, study) \
      rescue Research::CohortMembershipManager::StudentAlreadyInStudy
    run(:assign_missing_surveys, student: student)
  end

  def add_student_to_a_cohort(student, study)
    cohort_member = membership_manager(study).add_student_to_a_cohort(student)
    transfer_errors_from(cohort_member, {type: :verbatim}, true)
  end

  def membership_manager(study)
    @membership_managers ||= {}
    @membership_managers[study.id] ||= Research::CohortMembershipManager.new(study)
  end
end
