class TaskPlanAccessPolicy
  def self.action_allowed?(action, requestor, task_plan)
    case action
    when :read, :create, :update, :publish, :destroy, :stats
      return false unless requestor.is_human?
      case task_plan.owner
      when UserProfile::Profile
        task_plan.owner == requestor
      when Entity::User
        user = UserProfile::FindOrCreate.call(requestor).outputs.user
        user == task_plan.owner
      when Entity::Course
        ## Treat failure to positively identify the user
        ## as a course teacher as a denial of access.
        ## (This happens when the user is anonymous.)
        begin
          user = UserProfile::FindOrCreate.call(requestor).outputs.user
          Domain::UserIsCourseTeacher.call(user: user, course: task_plan.owner)
                                     .outputs.user_is_course_teacher
        rescue
          false
        end
      else
        false
      end
    else
      false
    end
  end
end
