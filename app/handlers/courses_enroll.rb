class CoursesEnroll
  lev_handler

  uses_routine CourseMembership::GetPeriod,             as: :get_period,       translations: { outputs: { type: :verbatim } }

  uses_routine CollectCourseInfo,                       as: :get_course_info,  translations: { outputs: {type: :verbatim  } }

  uses_routine UserIsCourseStudent,                     as: :is_student,       translations: { outputs: {type: :verbatim  } }

  protected

  def authorized?; true; end

  def handle
    run(:get_period, enrollment_code: params[:enroll_token])
    fatal_error(code: :enrollment_code_not_found) if outputs.period.nil?

    outputs.course = outputs.period.course

    run(:is_student, course: outputs.course, user: caller,
        include_dropped: true, include_archived: false)

    fatal_error(code: :period_is_archived) if outputs.period.deleted?
    fatal_error(code: :user_is_dropped)    if outputs.is_dropped

    fatal_error(code: :user_is_already_a_course_student) \
               if outputs.user_is_course_student && !outputs.is_dropped

    run(:get_course_info, courses: outputs.course, with: [:teacher_names])
  end

end
