class PeriodAccessPolicy
  def self.action_allowed?(action, requestor, period)
    return false unless requestor.is_human?

    course = period.course

    case action.to_sym
    when :read
      UserIsCourseStudent[user: requestor, course: course] ||
      UserIsCourseTeacher[user: requestor, course: course]
    when :create, :update, :destroy, :restore, :teacher_student
      UserIsCourseTeacher[user: requestor, course: course]
    else
      false
    end
  end
end
