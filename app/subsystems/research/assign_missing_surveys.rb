class Research::AssignMissingSurveys

  lev_routine

  def exec(survey_plan: nil, course: nil, student: nil)
    # Only one input should be present, if multiple are set only one
    # will be used.

    missing_surveys = missing_surveys_for_student(student) ||
                      missing_surveys_for_course(course) ||
                      missing_surveys_for_survey_plan(survey_plan)

    return if missing_surveys.blank? # e.g. if only non-published plans

    Research::Models::Survey.import!(missing_surveys)
  end

  def missing_surveys_for_student(student)
    return nil if student.nil?

    # Can find multiple surveys missing for this one student

    survey_plan_ids_not_assigned =
      Research::Models::SurveyPlan
        .published
        .not_hidden
        .joins{study.courses.students}
        .where{study.courses.students.id == my{student.id}}
        .where(
          <<-WHERE_SQL.strip_heredoc
            NOT EXISTS (
              SELECT *
              FROM "research_surveys"
              WHERE "research_surveys"."course_membership_student_id" = #{student.id}
              AND "research_surveys"."research_survey_plan_id" = "research_survey_plans"."id"
            )
          WHERE_SQL
        )
        .pluck(:id)

    survey_plan_ids_not_assigned.map do |survey_plan_id|
      Research::Models::Survey.new(
        course_membership_student_id: student.id,
        research_survey_plan_id: survey_plan_id,
      )
    end
  end

  def missing_surveys_for_survey_plan(survey_plan)
    return nil if survey_plan.nil? ||
                  !survey_plan.is_published? ||
                  survey_plan.is_hidden?

    # Can find multiple students missing this one survey

    student_ids_needing_survey = student_ids_needing_survey_for_plan(survey_plan)

    student_ids_needing_survey.map do |student_id|
      Research::Models::Survey.new(
        course_membership_student_id: student_id,
        research_survey_plan_id: survey_plan.id,
      )
    end
  end

  def missing_surveys_for_course(course)
    return nil if course.nil?

    # Can find multiple students missing multiple surveys

    survey_plans =
      Research::Models::SurveyPlan
        .published
        .not_hidden
        .joins{study.courses}
        .where{study.courses.id == my{course.id}}

    survey_plans.flat_map do |survey_plan|
      student_ids_needing_survey = student_ids_needing_survey_for_plan(survey_plan)

      student_ids_needing_survey.map do |student_id|
        Research::Models::Survey.new(
          course_membership_student_id: student_id,
          research_survey_plan_id: survey_plan.id,
        )
      end
    end
  end

  def student_ids_needing_survey_for_plan(survey_plan)
    CourseMembership::Models::Student
      .joins{course.studies}
      .where{course.studies.id == my{survey_plan.research_study_id}}
      .where(
        <<-WHERE_SQL.strip_heredoc
          NOT EXISTS (
            SELECT *
            FROM "research_surveys"
            WHERE "research_surveys"."course_membership_student_id" = "course_membership_students"."id"
            AND "research_surveys"."research_survey_plan_id" = #{survey_plan.id}
          )
        WHERE_SQL
    ).pluck(:id)
  end
end
