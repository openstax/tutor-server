class TaskAccessPolicy
  def self.action_allowed?(action, requestor, task)
    case action
    when :read
      requestor.is_human? && (
        (
          DoesTaskingExist[task_component: task, user: requestor] &&
          task.past_open?
        ) || (
          user_is_teacher?(requestor, task)
        )
      )
    when :change_is_late_work_accepted
      requestor.is_human? && user_is_teacher?(requestor, task)
    else
      false
    end
  end

  def self.get_entity_course(task)
    course = task.task_plan.try(:owner) ||  # normal course
             task.concept_coach_task.try(:task).try(:taskings).try(:first)
                                    .try(:period).try(:course) # cc course
    course.is_a?(Entity::Course) ? course : nil
  end

  def self.user_is_teacher?(user, task)
    (course = get_entity_course(task)).present? &&
    UserIsCourseTeacher[user: user, course: course]
  end

end
