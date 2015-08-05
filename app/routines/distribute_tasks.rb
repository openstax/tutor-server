class DistributeTasks

  lev_routine

  uses_routine IndividualizeTaskingPlans, as: :get_tasking_plans

  protected

  def exec(task_plan)
    # Lock the TaskPlan to prevent concurrent update/publish
    task_plan.lock!

    # Delete pre-existing assignments
    task_plan.tasks.destroy_all unless task_plan.tasks.empty?

    tasking_plans = run(:get_tasking_plans, task_plan).outputs.tasking_plans

    taskees = tasking_plans.collect { |tp| tp.target }
    opens_ats = tasking_plans.collect { |tp| tp.opens_at }
    due_ats = tasking_plans.collect { |tp| tp.due_at }

    assistant = task_plan.assistant

    # Call the assistant code to create Tasks, then distribute them
    tasks = assistant.build_tasks(task_plan: task_plan, taskees: taskees)
    tasks.each_with_index do |task, ii|
      role = taskees[ii]
      tasking = Tasks::Models::Tasking.new(
        task: task.entity_task,
        role: role,
        period: role.student.try(:period)
      )
      task.entity_task.taskings << tasking

      task.opens_at = opens_ats[ii]
      task.due_at = due_ats[ii] || (task.opens_at + 1.week)
      task.feedback_at ||= task.due_at
    end

    Tasks::Models::Task.import tasks, recursive: true

    task_plan.update_column(:published_at, Time.now)

    outputs[:tasks] = tasks
  end

end
