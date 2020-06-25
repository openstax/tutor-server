class TaskingPlanAccessPolicy
  def self.action_allowed?(action, requestor, tasking_plan)
    return false if requestor.is_anonymous? ||
                    !requestor.is_human? ||
                    action != :grade ||
                    !tasking_plan.past_due?

    UserIsCourseTeacher[user: requestor, course: tasking_plan.task_plan.course]
  end
end
