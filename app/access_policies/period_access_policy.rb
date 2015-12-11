class PeriodAccessPolicy
  def self.action_allowed?(action, requestor, period)
    course = period.course

    case action.to_sym
    when :read
      requestor.is_human? &&
        (UserIsCourseStudent.call(user: requestor, course: course) ||
           UserIsCourseTeacher.call(user: requestor, course: course))
    when :update, :destroy
      requestor.is_human? &&
       UserIsCourseTeacher.call(user: requestor, course: course)
    else
      false
    end
  end
end
