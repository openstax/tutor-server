class Tasks::Assistants::IReadingAssistant

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

  def self.logger
    Rails.logger
  end

  def self.tasked_reading(reading_fragment:, page:, step: nil)
    Tasks::Models::TaskedReading.new(task_step: step,
                                     url: page.url,
                                     title: reading_fragment.title,
                                     content: reading_fragment.to_html)
  end

  def self.tasked_exercise(exercise_fragment:, has_recovery: false, step: nil)
    if exercise_fragment.embed_tag.blank?
      logger.warn "Exercise without embed tag found while creating iReading"
      return
    end

    # Search local (cached) Exercises for one matching the embed tag
    exercises = Content::SearchLocalExercises[tag: exercise_fragment.embed_tag]
    exercise = exercises.first

    Tasks::Models::TaskedExercise.new(task_step: step,
                                      url: exercise.url,
                                      title: exercise.title,
                                      content: exercise.content,
                                      has_recovery: has_recovery)
  end

  def self.tasked_video(video_fragment:, step: nil)
    if video_fragment.url.blank?
      logger.warn "Video without embed tag found while creating iReading"
      return
    end

    Tasks::Models::TaskedVideo.new(task_step: step,
                                   url: video_fragment.url,
                                   title: video_fragment.title,
                                   content: video_fragment.to_html)
  end

  def self.tasked_interactive(interactive_fragment:, step: nil)
    if interactive_fragment.url.blank?
      logger.warn('Interactive without iframe found while creating iReading')
      return
    end

    Tasks::Models::TaskedInteractive.new(task_step: step,
                                         url: interactive_fragment.url,
                                         title: interactive_fragment.title,
                                         content: interactive_fragment.to_html)
  end

  def self.distribute_tasks(task_plan:, taskees:)
    title = task_plan.title || 'iReading'
    opens_at = task_plan.opens_at
    due_at = task_plan.due_at || (task_plan.opens_at + 1.week)

    page_ids = task_plan.settings['page_ids']
    cnx_pages = page_ids.collect do |page_id|
      Content::GetPage.call(id: page_id).outputs.page
    end

    # Assign Tasks to taskees and return the Task array
    taskees.collect do |taskee|
      task = Tasks::CreateTask[task_plan: task_plan,
                               task_type: 'reading',
                               title: title,
                               opens_at: opens_at,
                               due_at: due_at]

      cnx_pages.each do |page|
        page.fragments.each do |fragment|
          step = Tasks::Models::TaskStep.new(task: task, page_id: page.id)

          step.tasked = case fragment
          when OpenStax::Cnx::V1::Fragment::ExerciseChoice
            exercises = fragment.exercise_fragments
            tasked_exercise(exercise_fragment: exercises.sample,
                            has_recovery: true,
                            step: step)
          when OpenStax::Cnx::V1::Fragment::Exercise
            tasked_exercise(exercise_fragment: fragment, step: step)
          when OpenStax::Cnx::V1::Fragment::Video
            tasked_video(video_fragment: fragment, step: step)
          when OpenStax::Cnx::V1::Fragment::Interactive
            tasked_interactive(interactive_fragment: fragment, step: step)
          else
            tasked_reading(reading_fragment: fragment, page: page, step: step)
          end

          next if step.tasked.nil?

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

          step = Tasks::Models::TaskStep.new(task: task)
          step.tasked = Tasks::Models::TaskedExercise.new(
                                           task_step: step,
                                           title: ex.title,
                                           url: ex.url,
                                           content: ex.content)
          task.task_steps << step
        end
      end

      # No group tasks for this assistant
      task.entity_task.taskings << Tasks::Models::Tasking.new(
        task: task.entity_task, role: taskee
      )

      task.save!
      task
    end
  end

end
