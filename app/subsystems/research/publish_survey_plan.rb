class Research::PublishSurveyPlan

  lev_routine

  uses_routine Research::AssignMissingSurveys, as: :assign_missing_surveys,
                                               translations: { outputs: { type: :verbatim } }

  def exec(survey_plan:)
    raise "Cannot publish an already-published survey plan" if survey_plan.is_published?

    run(:assign_missing_surveys, survey_plan: survey_plan)

    survey_plan.update_attributes(published_at: Time.current)
    transfer_errors_from(survey_plan, {type: :verbatim}, true)
  end
end
