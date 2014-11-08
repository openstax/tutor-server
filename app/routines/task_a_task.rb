class TaskATask
  lev_routine

protected

  def exec(task:, taskee:)
    outputs[:tasking] = Tasking.create(
      taskee: taskee,
      user_id: taskee.user_id,
      task: task
    )

    transfer_errors_from(outputs[:tasking], {type: :verbatim}, true)

    # TODO notify assignee
  end

end