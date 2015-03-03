class TaskPlanAccessPolicy
  def self.action_allowed?(action, requestor, task_plan)
    case action
    when :read, :create, :update, :publish, :destroy
      return false unless requestor.is_human?
      case task_plan.owner
      when User
        task_plan.owner == requestor
      when Entity::User
        user = LegacyUser::FindOrCreateUserForLegacyUser.call(
          requestor
        ).outputs.user
        user == task_plan.owner
      when Entity::Course
        user = LegacyUser::FindOrCreateUserForLegacyUser.call(
                 requestor
               ).outputs.user
        Domain::UserIsCourseTeacher.call(user: user, course: task_plan.owner)
                                   .outputs.user_is_course_teacher
      else
        false
      end
    else
      false
    end
  end
end
