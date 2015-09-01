class DistributeTasks

  lev_routine

  uses_routine IndividualizeTaskingPlans, as: :get_tasking_plans

  protected

  def save(entity_tasks)
    entity_tasks.each do |entity_task|
      entity_task.task.task_steps.each_with_index do |task_step, index|
        tasked = task_step.tasked
        tasked.task_step = nil
        tasked.save!
        task_step.tasked = tasked
        task_step.number = index + 1
      end

      entity_task.task.update_step_counts
    end

    Entity::Task.import! entity_tasks, recursive: true
  end

  def exec(task_plan, publish_time = Time.now)
    # Lock the TaskPlan to prevent concurrent update/publish
    task_plan.lock!

    tasks = task_plan.tasks.preload(:entity_task, { taskings: :role })

    # Delete pre-existing (unopened) assignments
    tasks.each do |tt|
      next if tt.opens_at <= publish_time
      tt.entity_task.destroy
    end

    tasked_taskees = tasks.select{ |tt| !tt.destroyed? }
                          .flat_map{ |tt| tt.taskings.collect{ |tk| tk.role } }

    tasking_plans = run(:get_tasking_plans, task_plan).outputs.tasking_plans

    taskees = tasking_plans.collect{ |tp| tp.target }
    opens_ats = tasking_plans.collect{ |tp| tp.opens_at }
    due_ats = tasking_plans.collect{ |tp| tp.due_at }

    # Exclude students that already had the assignment
    untasked_taskees = taskees - tasked_taskees

    assistant = task_plan.assistant

    # Call the assistant code to create Tasks, then distribute them
    entity_tasks = assistant.build_tasks(task_plan: task_plan, taskees: untasked_taskees)
    entity_tasks.each_with_index do |entity_task, ii|
      role = untasked_taskees[ii]
      tasking = Tasks::Models::Tasking.new(
        task: entity_task,
        role: role,
        period: role.student.try(:period)
      )
      entity_task.taskings << tasking

      task = entity_task.task
      task.opens_at = opens_ats[ii]
      task.due_at = due_ats[ii] || (task.opens_at + 1.week)
      task.feedback_at ||= task.due_at
    end

    save(entity_tasks)

    task_plan.update_column(:published_at, publish_time) \
      if task_plan.published_at.nil? && task_plan.persisted?

    outputs[:entity_tasks] = entity_tasks
  end

end
