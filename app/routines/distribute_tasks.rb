class DistributeTasks

  lev_routine

  uses_routine IndividualizeTaskingPlans, as: :individualize_tasking_plans

  protected

  def exec(task_plan, publish_time = Time.current, protect_unopened_tasks = false)
    task_plan.lock!

    fatal_error(code: :publish_last_requested_at_must_be_in_the_past) \
      if task_plan.publish_last_requested_at.present? &&
         task_plan.publish_last_requested_at > publish_time

    tasks = task_plan.tasks.preload(:taskings)

    # Delete pre-existing assignments only if
    # no assignments are open and protect_unopened_tasks is false
    tasks.each(&:really_destroy!) \
      if !protect_unopened_tasks &&
         tasks.none?{ |task| task.past_open?(current_time: publish_time) }

    tasked_role_ids = tasks.reject(&:destroyed?).flat_map do |task|
      task.taskings.map(&:entity_role_id)
    end

    tasking_plans = run(:individualize_tasking_plans, task_plan).outputs.tasking_plans
    untasked_tasking_plans = tasking_plans.reject do |tasking_plan|
      tasked_role_ids.include? tasking_plan.target_id
    end

    assistant = task_plan.assistant

    # Call the assistant code to create Tasks, then distribute them
    tasks = assistant.build_tasks(
      task_plan: task_plan, individualized_tasking_plans: untasked_tasking_plans
    )

    fatal_error(
      code: :empty_tasks, message: 'Tasks could not be published because some tasks were empty'
    ) if tasks.any?{ |task| !task.stepless? && task.task_steps.empty? }

    save(tasks)

    task_plan.first_published_at = publish_time if task_plan.first_published_at.nil?
    task_plan.last_published_at = publish_time
    # We are only changing timestamps here, so no reason to validate the record
    task_plan.save(validate: false) if task_plan.persisted?

    outputs[:tasks] = tasks
  end

  # Efficiently save all task records
  def save(tasks)
    # Taskeds are not saved by recursive: true because they are a belongs_to association
    # So we handle them separately
    all_taskeds = tasks.map do |task|
      task.update_step_counts

      task.task_steps.map do |task_step|
        task_step.tasked
      end
    end

    all_taskeds.flatten.group_by(&:class).each do |tasked_class, taskeds|
      tasked_class.import taskeds, validate: false
    end

    tasks.each_with_index do |task, task_index|
      task.task_steps.each_with_index do |task_step, step_index|
        task_step.tasked = all_taskeds[task_index][step_index]
        task_step.number = step_index + 1
      end
    end

    Tasks::Models::Task.import tasks, recursive: true, validate: false

    tasks.each do |task|
      task.task_steps.reset
      task.tasked_exercises.reset
      task.taskings.reset
    end
  end

end
