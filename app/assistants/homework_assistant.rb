class HomeworkAssistant

  # Array of arrays [Events ago, number of spaced practice questions]
  # This has to change, but for now add 4 questions to simulate what
  # Kathi's algorithm would give us for a reading with 2 LO's
  # (the sample content)
  SPACED_PRACTICE_MAP = [[1, 4]]

  def self.schema
    '{
      "type": "object",
      "required": [
        "exercise_ids"
      ],
      "properties": {
        "exercise_ids": {
          "type": "array",
          "items": {
            "type": "integer"
          }
        }
      },
      "additionalProperties": false
    }'
  end

  def self.add_exercise_step(task:, exercise:)
    step = TaskStep.new(task: task)

    step.tasked = TaskedExercise.new(task_step: step,
                                     url: exercise.url,
                                     title: exercise.title,
                                     content: exercise.content)

    task.task_steps << step
  end

  def self.distribute_tasks(task_plan:, taskees:)
    title = task_plan.title || 'Homework'
    opens_at = task_plan.opens_at
    due_at = task_plan.due_at || (task_plan.opens_at + 1.week)

    exercise_ids = task_plan.settings['exercise_ids']
    exercises = exercise_ids.collect do |exercise_id|
      Content::GetExercise.call(id: exercise_id).outputs.exercise
    end

    # Assign Tasks to taskees and return the Task array
    taskees.collect do |taskee|
      task = Task.new(task_plan: task_plan,
                      task_type: 'homework',
                      title: title,
                      opens_at: opens_at,
                      due_at: due_at)

      exercises.each do |exercise|
        add_exercise_step(task: task, exercise: exercise)
      end

      # Spaced practice
      # TODO: Make a SpacedPracticeStep that does this
      #       right before the user gets the question
      SPACED_PRACTICE_MAP.each do |k_ago, number|
        number.times do
          exercise = FillIReadingSpacedPracticeSlot.call(taskee, k_ago)
                                                   .outputs.exercise

          add_exercise_step(task: task, exercise: exercise)
        end
      end

      # No group tasks for this assistant
      task.taskings << Tasking.new(task: task, taskee: taskee, user: taskee)

      task.save!

      task
    end
  end

end
