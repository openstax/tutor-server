class Research::PublishSurveyPlan

  lev_routine

  def exec(survey_plan:)
    raise "Cannot publish an already-published survey plan" if survey_plan.is_published?

    # TODO move most of this into AssignMissingSurveys

    student_ids =
      CourseMembership::Models::Student
        .joins{course.studies.survey_plans}
        .where{course.studies.survey_plans.id == my{survey_plan.id}}
        .pluck(:id)

    # Add code to not assign surveys that already exist

    surveys = student_ids.map do |student_id|
      Research::Models::Survey.new(
        course_membership_student_id: student_id,
        research_survey_plan_id: survey_plan.id,
      )
    end

    Research::Models::Survey.import!(surveys)

    survey_plan.update_attributes(published_at: Time.current)
    transfer_errors_from(survey_plan, {type: :verbatim}, true)
  end
end
