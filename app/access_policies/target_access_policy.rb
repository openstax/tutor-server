class TargetAccessPolicy
  def self.action_allowed?(action, requestor, target)
    case action
    when :task
      course = case requestor
      when Entity::Course
        requestor
      else
        raise NotYetImplemented
      end

      case target
      when Entity::Role
        CourseMembership::IsCourseStudent[roles: target, course: course]
      when User::User
        UserIsCourseStudent[user: target, course: course]
      when Entity::Course
        target == course
      when CourseMembership::Models::Period
        course.periods.include?(target)
      else
        raise NotYetImplemented
      end
    else
      false
    end
  end
end
