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
      when UserProfile::Models::Profile
        UserIsCourseStudent[user: target.entity_user, course: course]
      when Entity::User
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
