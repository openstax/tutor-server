class TaskedAccessPolicy
  def self.action_allowed?(action, requestor, tasked)
    case action
    when :read
      requestor.is_human? && (
        (DoesTaskingExist[task_component: tasked, user: requestor.user] &&
         tasked.task_step.task.past_open?) ||
        UserIsCourseTeacher[user: requestor.user, course: tasked.task_step.task.task_plan.owner]
      )
    when :update, :mark_completed, :recover, :refresh
      requestor.is_human? &&
      DoesTaskingExist[task_component: tasked, user: requestor.user] &&
      tasked.task_step.task.past_open?
    else
      false
    end
  end
end
