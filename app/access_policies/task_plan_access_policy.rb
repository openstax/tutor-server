class TaskPlanAccessPolicy
  def self.action_allowed?(action, requestor, task_plan)
    case action
    when :read, :create, :update, :publish, :destroy, :stats
      if task_plan.owner.is_a?(Entity::Course)
        user_is_course_teacher?(requestor.entity_user, task_plan.owner)
      elsif requestor.is_human?
        requestor_is_task_plan_owner?(requestor, task_plan.owner)
      else
        false
      end
    else
      false
    end
  end

  private

  def self.user_is_course_teacher?(user, course)
    Domain::UserIsCourseTeacher.call(user: user, course: course)
                               .outputs.user_is_course_teacher rescue false
  end

  def self.requestor_is_task_plan_owner?(requestor, owner)
    requestor == owner || requestor.entity_user == owner
  end

end
