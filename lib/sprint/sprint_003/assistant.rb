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
        task_step = send("create_#{step_config.type}_step", task, step_config)
      end

      task
    end

    def create_homework_task(task_plan)
      task = create_base_task(task_plan)
      number = 0
      task_plan.configuration.manual_exercises.each do |ex_id|
        ed = ExerciseDefinition.find(ex_id)
        exercise_step = CreateExercise.call(task, "##{number += 1}", url: ed.url, content: ed.content)
      end

      if task_plan.configuration.spaced_exercises?
        task_plan.configuration.spaced_exercises.tap do |se|
          topic = GetOrCreateTopic.call(topic: se.topic, klass: task_plan.owner).outputs.topic
          eds = topic.exercise_definitions

          se.num_exercises.times do |ii|
            ed = eds[eds.length-ii-1]
            exercise_step = CreateExercise.call(task, "##{number += 1}", url: ed.url, content: ed.content)
          end
        end
      end

      if task_plan.configuration.personalized_exercises?
        task_plan.configuration.personalized_exercises.tap do |pe|
          topic = GetOrCreateTopic.call(topic: pe.topic, klass: task_plan.owner).outputs.topic
          allowed_exercise_definitions = topic.exercise_definitions.reject{|ed| Exercise.joins(:resource).where{resource.url == ed.url}.any?}

          eds = BigLearn.projection_next_questions(allowed_exercise_definitions: allowed_exercise_definitions, learner: '12345', count: pe.num_exercises)

          eds.each do |edef|
            exercise_step = CreateExercise.call(task, "##{number += 1}", url: edef.url, content: edef.content)
          end
        end
      end

      task
    end

    def create_reading_step(task, config)
      CreateReading.call(task, config.slice(:url)).outputs[:task_step]
    end

    def create_interactive_step(task, config)
      CreateInteractive.call(task, config.slice(:url)).outputs[:task_step]
    end

    def create_exercise_step(task, title, config)

    end

  end
end