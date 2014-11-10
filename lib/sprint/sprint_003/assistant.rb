module Sprint003
  class Assistant < ::AssistantBase

    configure schema: {}

    supports_task_plan type: :study, schema: {}
    supports_task_plan type: :homework, schema: {}

    def task_taskees(task_plan, taskees)
      taskees.each do |taskee|
        # branching based on cohort membership would happen somewhere around here
        task = create_task(task_plan)
        TaskATask.call(task: task, taskee: taskee)  # TODO can this live in base?
      end
    end

    def validate_task_plan(task_plan)
      []
    end

    def create_task(task_plan)
      send("create_#{task_plan.type}_task", task_plan)
    end

    def create_base_task(task_plan)    # TODO can this live in base?
      Task.create(title: task_plan.title, 
                  opens_at: task_plan.opens_at, 
                  due_at: task_plan.due_at,
                  task_plan: task_plan)
    end

    def create_study_task(task_plan)
      task = create_base_task(task_plan)
      # TODO need a step somewhere to validate task_plan.configuration against plan schema
      task_plan.configuration.steps.each do |step_config|
        debugger
        task_step = send("create_#{step_config.type}_step", task, step_config)
        debugger
      end; debugger

      task
    end

    def create_homework_task(task_plan)
      create_base_task(task_plan)
    end

    def create_reading_step(task, config)
      CreateReading.call(task, config.slice(:url)).outputs[:task_step]
    end

    def create_interactive_step(task, config)
      CreateInteractive.call(task, config.slice(:url)).outputs[:task_step]
    end

  end
end