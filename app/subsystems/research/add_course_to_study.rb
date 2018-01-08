class Research::AddCourseToStudy

  lev_routine

  uses_routine Research::AssignMissingSurveys, as: :assign_missing_surveys,
                                               translations: { outputs: { type: :verbatim } }

  def exec(course:, study:)
    study_course = Research::Models::StudyCourse.create(course: course, study: study)
    transfer_errors_from(study_course, {type: :verbatim}, true)

    run(:assign_missing_surveys, course: course)
  end

end
