class Research::RemoveCourseFromStudy

  lev_routine

  def exec(course: nil, study: nil, study_course: nil)
    study_course ||= Research::Models::StudyCourse.where(course: course, study: study).first
    course ||= study_course.course
    study ||= study_course.study

    fatal_error(:cannot_remove_course_from_ever_active_study) if study.ever_active?

    Research::CohortMembershipManager.new(study).remove_students_from_cohorts(course.students)

    study_course.destroy
    transfer_errors_from(study_course, {type: :verbatim}, true)
  end

end
