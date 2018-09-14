# Adds the given role to the given period
class CourseMembership::AddStudent
  lev_routine express_output: :student

  uses_routine CourseMembership::AddEnrollment,
               as: :add_enrollment,
               translations: { outputs: { type: :verbatim } }

  uses_routine CourseProfile::MarkCourseEnrolled,
               as: :mark_course_enrolled, translations: { outputs: { type: :verbatim } }

  uses_routine Research::AdmitStudentsToStudies, as: :admit_students_to_studies,
                                                 translations: { outputs: { type: :verbatim } }

  protected

  def exec(period:, role:, student_identifier: nil,
           reassign_published_period_task_plans: true, send_to_biglearn: true)
    student = CourseMembership::Models::Student.find_by(role: role)
    fatal_error(
      code: :already_a_student, message: "The provided role is already a student in #{
        student.course.name || 'some course'
      }."
    ) unless student.nil?

    course = period.course

    student = CourseMembership::Models::Student.create(role: role,
                                                       course: course,
                                                       period: period.to_model,
                                                       student_identifier: student_identifier)
    transfer_errors_from(student, {type: :verbatim}, true)

    run(
      :add_enrollment,
      period: period,
      student: student,
      reassign_published_period_task_plans: reassign_published_period_task_plans,
      send_to_biglearn: send_to_biglearn
    )

    run(:mark_course_enrolled, course: course)

    run(:admit_students_to_studies, students: student, studies: course.studies)
  end
end
