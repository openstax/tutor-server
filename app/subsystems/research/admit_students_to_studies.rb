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
    cohort_member = membership_manager(study).add_student_to_a_cohort(student)
    transfer_errors_from(cohort_member, {type: :verbatim}, true)

    # TODO assign_missing_surveys goes here? (and remove from CourseMembership::AddStudent)
  end

  def membership_manager(study)
    begin
      @membership_managers ||= {}
      @membership_managers[study.id] ||= Research::CohortMembershipManager.new(study)
    rescue Research::CohortMembershipManager::StudyHasBeenActive => ee
      fatal_error(code: :cannot_manage_cohort_membership_if_study_ever_active)
    end
  end
end
