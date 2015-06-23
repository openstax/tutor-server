class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? && 
      (DoesTaskingExist[task_component: task, user: requestor] || \
       UserIsCourseTeacher[user: requestor.entity_user, course: task.task_plan.owner])
    else
      false
    end
  end
end
