class Research::CreateCohort

  lev_routine

  # uses_routine Research::RebalanceCohorts, as: :create_offering,
  #                                          translations: { outputs: { type: :verbatim } }

  protected

  def exec(name:, study:)
    fatal_error(code: :study_already_active) if study.active?

    cohort = Research::Models::Cohort.create(name: name, study: study)
    transfer_errors_from(cohort, {type: :verbatim}, true)

    run(:rebalance_cohorts, study: study)
  end
end
