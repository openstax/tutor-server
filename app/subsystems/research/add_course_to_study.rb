class Research::AddCourseToStudy

  lev_routine

  uses_routine Research::AdmitStudentsToStudies, as: :admit_students_to_studies,
                                                 translations: { outputs: { type: :verbatim } }

  def exec(course:, study:)
    study_course = Research::Models::StudyCourse.create(course: course, study: study)
    transfer_errors_from(study_course, {type: :verbatim}, true)

    run(:admit_students_to_studies, students: course.students, studies: study)
  end

end
