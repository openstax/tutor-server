class Research::CreateCohort # TODO maybe kill this - if go with plan to make dumb cohorts with
                             # no other actions triggered

  lev_routine

  protected

  def exec(name:, study:)
    fatal_error(code: :study_already_active) if study.active?

    cohort = Research::Models::Cohort.create(name: name, study: study)
    transfer_errors_from(cohort, {type: :verbatim}, true)
  end
end
