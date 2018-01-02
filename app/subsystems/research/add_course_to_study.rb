class Research::AddCourseToStudy

  lev_routine

  def exec(course:, study:)
    study_course = Research::Models::StudyCourse.create(course: course, study: study)
    transfer_errors_from(study_course, {type: :verbatim}, true)

    # TODO assign surveys that are published
  end

end
