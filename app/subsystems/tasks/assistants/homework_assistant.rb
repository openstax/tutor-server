class Tasks::Assistants::HomeworkAssistant

  def self.schema
    '{
      "type": "object",
      "required": [
        "exercise_ids",
        "exercises_count_dynamic"
      ],
      "properties": {
        "exercise_ids": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        },
        "exercises_count_dynamic": {
          "type": "integer",
          "minimum": 2,
          "maximum": 4
        },
        "description": {
          "type": "string"
        },
        "page_ids": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        }
      },
      "additionalProperties": false
    }'
  end

  def self.distribute_tasks(task_plan:, taskees:)
    exercises = collect_exercises(task_plan: task_plan)

    tasks = taskees.collect do |taskee|
      task = create_homework_task!(
        task_plan: task_plan,
        taskee:    taskee,
        exercises: exercises
      )
      assign_task!(task: task, taskee: taskee)
      task
    end

    tasks
  end

  def self.collect_exercises(task_plan:)
    exercises = task_plan.settings['exercise_ids'].collect do |exercise_id|
      Content::GetExercise.call(id: exercise_id).outputs.exercise
    end
    exercises
  end

  def self.create_homework_task!(task_plan:, taskee:, exercises:)
    task = create_task!(task_plan: task_plan)
    add_core_steps!(task: task, exercises: exercises)
    add_spaced_practice_exercise_steps!(task: task, taskee: taskee)
  end

  def self.create_task!(task_plan:)
    title    = task_plan.title || 'Homework'
    opens_at = task_plan.opens_at
    due_at   = task_plan.due_at || (task_plan.opens_at + 1.week)

    description = task_plan.settings['description']

    task = Tasks::CreateTask[
      task_plan:   task_plan,
      task_type:   'homework',
      title:       title,
      description: description,
      opens_at:    opens_at,
      due_at:      due_at,
      feedback_at: due_at
    ]

    task.save!
    task
  end

  def self.add_core_steps!(task:, exercises:)
    exercises.each do |exercise|
      add_exercise_step(task: task, exercise: exercise)
    end

    task.save!
    task
  end

  def self.add_exercise_step(task:, exercise:)
    step = Tasks::Models::TaskStep.new(task: task)
    TaskExercise[task_step: step, exercise: exercise]
    task.task_steps << step
    task
  end

  def self.add_spaced_practice_exercise_steps!(task:, taskee:)
    k_ago_map = [[1, 4]]
    k_ago_map.each do |k_ago, number|
      number.times do
        hash = OpenStax::Exercises::V1.fake_client.new_exercise_hash
        exercise = OpenStax::Exercises::V1::Exercise.new(hash.to_json)
        add_exercise_step(task: task, exercise: exercise)
      end
    end

    task.save!
    task
  end

  def self.assign_task!(task:, taskee:)
    # No group tasks for this assistant
    task.entity_task.taskings << Tasks::Models::Tasking.new(
      task: task.entity_task,
      role: taskee
    )

    task.save!
    task
  end

end
