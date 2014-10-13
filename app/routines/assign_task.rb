class AssignTask
  lev_routine

protected

  def exec(task:, assignee:)

    individual_assignees = []

    # If the "task" passed in is a detailed task (like "Reading"), get the
    # generic Task above it.
    task = task.task if !task.is_a? Task

    case assignee
    when Student
      individual_assignees.push(assignee: assignee, user_id: assignee.user_id)
    when User
      individual_assignees.push(assignee: assignee, user_id: assignee.id)
    # when TaskPlanAssignee
    #   break it down (once this class is implemented)
    else
      raise NotYetImplemented
    end

    outputs[:assigned_tasks] = []
    
    individual_assignees.each do |individual_assignee|

      assigned_task = AssignedTask.create(
        assignee: individual_assignee[:assignee],
        user_id: individual_assignee[:user_id],
        task: task
      )

      # TODO notify assignee

      outputs[:assigned_tasks].push(assigned_task)
    end

  end

end