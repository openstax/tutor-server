class CoursesEnroll
  lev_handler

  uses_routine CourseMembership::GetPeriod, as: :get_period,
                                            translations: { outputs: { type: :verbatim } }
  uses_routine CollectCourseInfo, translations: { outputs: {type: :verbatim} }

  protected

  def authorized?; true; end

  def handle
    run(:get_period, enrollment_code: params[:enroll_token])
    fatal_error(code: :enrollment_code_not_found) if outputs.period.nil?
    outputs.course = outputs.period.course

    user_test = UserIsCourseStudent.call(
      course: outputs.period.course, user: caller,
      include_dropped: true, include_archived: true
    ).outputs

    fatal_error(code: :user_is_an_inactive_student) \
               if user_test.is_dropped || user_test.is_archived

    fatal_error(code: :user_is_already_a_course_student) \
               if user_test.user_is_course_student

    run(:collect_course_info, courses: outputs.period.course, with: [:teacher_names])
  end

end
