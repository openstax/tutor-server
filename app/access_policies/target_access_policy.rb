class TargetAccessPolicy
  def self.action_allowed?(action, requestor, target)
    case action
    when :task
      course = case requestor
      when CourseProfile::Models::Course
        requestor
      else
        raise NotYetImplemented
      end

      case target
      when Entity::Role
        CourseMembership::IsCourseStudent[roles: target, course: course]
      when ::User::Models::Profile
        strategy = ::User::Strategies::Direct::User.new(target)
        user = ::User::User.new(strategy: strategy)
        UserIsCourseStudent[user: user, course: course]
      when CourseProfile::Models::Course
        target == course
      when CourseMembership::Models::Period
        course.periods.with_deleted.include?(target)
      else
        raise NotYetImplemented
      end
    else
      false
    end
  end
end
