class Research::UnhideSurveyPlan

  # **** Shouldn't be used ****
  #
  # But... because someone will likely ask for this, we'll have this
  # ready for a dev to run on the console

  lev_routine

  uses_routine Research::AssignMissingSurveys, as: :assign_missing_surveys,
                                               translations: { outputs: { type: :verbatim } }

  def exec(survey_plan:)
    return if !survey_plan.is_hidden?

    survey_plan.update_attributes(permanently_hidden_at: nil)
    transfer_errors_from(survey_plan, {type: :verbatim}, true)

    survey_plan.surveys.update_all(permanently_hidden_at: nil)

    # Between the time that the survey was hidden and unhidden, students may have been
    # added to its study, so we need to assign those missing surveys

    run(:assign_missing_surveys, survey_plan: survey_plan) if survey_plan.is_published?
  end
end
