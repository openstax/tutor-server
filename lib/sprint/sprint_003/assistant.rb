module Sprint003
  class Assistant < ::AssistantBase

    configure schema: {}

    supports_task_plan type: :study, schema: {}
    supports_task_plan type: :homework, schema: {}

    def task_taskees(task_plan, taskees)
      taskees.each do |taskee|
        task = build_task(task_plan)
        task.save
        TaskATask.call(task: task, taskee: taskee)  # TODO can this live in base?
      end
    end

    def build_task(task_plan)
      send("build_#{task_plan.type}_task", task_plan)
    end

    def build_base_task(task_plan)    # TODO can this live in base?
      Task.new(title: task_plan.title, 
               opens_at: task_plan.opens_at, 
               due_at: task_plan.due_at,
               task_plan: task_plan)
    end

    def build_study_task(task_plan)
      task = build_base_task(task_plan)
      # TODO need a step somewhere to validate task_plan.configuration against plan schema
      task_plan.configuration.steps.each do |step_config|
        step = send("build_#{step_config.type}_step", step_config)
        task.task_steps << step
      end

      task
    end

    def build_reading_step(config)
      CreateReading.call(config.slice(:url)).outputs[:task_step]
    end

  end
end