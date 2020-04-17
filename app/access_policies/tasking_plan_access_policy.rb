class TaskingPlanAccessPolicy
  def self.action_allowed?(action, requestor, tasking_plan)
    return false if requestor.is_anonymous? || !requestor.is_human? ||
                    action != :grade || !tasking_plan.past_due?

    owner = tasking_plan.task_plan.owner
    if owner.is_a?(CourseProfile::Models::Course)
      UserIsCourseTeacher[user: requestor, course: owner]
    else
      requestor == owner
    end
  end
end
