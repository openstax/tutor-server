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
        CourseMembership::IsCourseStudent.call(roles: target, course: course)
      when ::User::Models::Profile
        strategy = ::User::Strategies::Direct::User.new(target)
        user = ::User::User.new(strategy: strategy)
        UserIsCourseStudent.call(user: user, course: course)
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
