class Research::ReassignMembers

  lev_routine

  def exec(cohort)
    fatal_error(code: :cannot_move_members_in_ever_active_study) if cohort.study.ever_active?

    membership_manager = Research::CohortMembershipManager.new(cohort.study)

    begin
      membership_manager.reassign_cohort_members(cohort)
    rescue Research::CohortMembershipManager::NoCohortsAvailable => ee
      fatal_error(code: :no_cohorts_available_to_reassign_to)
    rescue ActiveRecord::RecordInvalid => ee
      fatal_error(code: :could_not_move_a_member, message: ee.message)
    end
  end

end
