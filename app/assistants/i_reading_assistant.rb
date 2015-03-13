class IReadingAssistant

  # Array of arrays [Events ago, number of spaced practice questions]
  # This has to change, but for now add 4 questions to simulate what
  # Kathi's algorithm would give us for a reading with 2 LO's
  # (the sample content)
  SPACED_PRACTICE_MAP = [[1, 4]]

  def self.schema
    '{
      "type": "object",
      "required": [
        "page_ids"
      ],
      "properties": {
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
    title = task_plan.title || 'iReading'
    opens_at = task_plan.opens_at
    due_at = task_plan.due_at || (task_plan.opens_at + 1.week)

    page_ids = task_plan.settings['page_ids']
    cnx_pages = page_ids.collect do |page_id|
      Content::Api::GetPage.call(id: page_id).outputs.page
    end

    # Assign Tasks to taskees and return the Task array
    taskees.collect do |taskee|
      task = Task.new(task_plan: task_plan,
                      task_type: 'reading',
                      title: title,
                      opens_at: opens_at,
                      due_at: due_at)

      cnx_pages.each do |page|
        page.fragments.each do |fragment|
          step = TaskStep.new(task: task)

          step.tasked = case fragment
          when OpenStax::Cnx::V1::Fragment::Exercise
            # TODO: Exercises are cached locally during book import,
            # so this search can be local, but
            # need to store short code tags in Tutor separately from the JSON
            exercise = OpenStax::Exercises::V1.exercises(
              tag: fragment.embed_tag
            )['items'].first

            TaskedExercise.new(task_step: step, url: exercise.url,
                               title: exercise.title, content: exercise.content)
          else
            TaskedReading.new(task_step: step, url: page.url,
                              title: fragment.title, content: fragment.to_html)
          end

          task.task_steps << step
        end
      end

      # Spaced practice
      # TODO: Make a SpacedPracticeStep that does this
      #       right before the user gets the question
      SPACED_PRACTICE_MAP.each do |k_ago, number|
        number.times do
          ex = FillIReadingSpacedPracticeSlot.call(taskee, k_ago)
                                             .outputs[:exercise]

          step = TaskStep.new(task: task)
          step.tasked = TaskedExercise.new(task_step: step,
                                           title: ex.title,
                                           url: ex.url,
                                           content: ex.content)
          task.task_steps << step
        end
      end

      # No group tasks for this assistant
      task.taskings << Tasking.new(task: task, taskee: taskee, user: taskee)

      task.save!
      task
    end
  end

end
