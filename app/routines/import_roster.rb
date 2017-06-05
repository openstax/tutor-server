class ImportRoster

  lev_routine

  uses_routine User::FindOrCreateUser, as: :find_or_create_user,
                                       translations: { outputs: { type: :verbatim } }
  uses_routine AddUserAsPeriodStudent, as: :add_user_as_period_student
  uses_routine ReassignPublishedPeriodTaskPlans, as: :reassign_published_period_task_plans

  protected

  def exec(user_hashes:, period:)
    user_hashes.each do |user_hash|
      user = run(:find_or_create_user, user_hash).outputs.user

      run(
        :add_user_as_period_student,
        period: period,
        user: user,
        assign_published_period_tasks: false
      )
    end

    run(:reassign_published_period_task_plans, period: period)
  end

end
