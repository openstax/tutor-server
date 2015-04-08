class Tasks::Assistants::IReadingAssistant

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
    ## NOTE: This implementation isn't particularly robust: failure to distribute to any taskee will
    ##       result in failure to distribute to EVERY taskee (because the entire transaction will be
    ##       rolled back).  Eventually, we will probably want to create an "undistributed" task and
    ##       have per-taskee workers (with per-taskee transactions) build and distribute the tasks.

    cnx_pages = collect_cnx_pages(task_plan: task_plan)

    tasks = taskees.collect do |taskee|
      task = create_ireading_task!(
        task_plan: task_plan,
        taskee:    taskee,
        cnx_pages: cnx_pages
      )
      assign_task!(task: task, taskee: taskee)
      task
    end

    tasks
  end

  protected

  def self.collect_cnx_pages(task_plan:)
    page_ids = task_plan.settings['page_ids']
    cnx_pages = page_ids.collect do |page_id|
      Content::GetPage.call(id: page_id).outputs.page
    end
    cnx_pages
  end

  def self.create_ireading_task!(task_plan:, taskee:, cnx_pages:)
    task = create_task!(task_plan: task_plan)
    add_core_steps!(task: task, cnx_pages: cnx_pages)
    add_spaced_practice_exercise_steps!(task: task, taskee: taskee)
    # add_coverage_exercise_steps!(task: task, taskee: taskee)
    # add_personalized_exercise_steps!(task: task, taskee: taskee)

    task.save!
    task
  end

  def self.assign_task!(task:, taskee:)
    # No group tasks for this assistant
    tasking = Tasks::Models::Tasking.new(
      task: task.entity_task,
      role: taskee
    )
    task.entity_task.taskings << tasking

    task.save!
    task
  end

  def self.create_task!(task_plan:)
    title    = task_plan.title || 'iReading'
    opens_at = task_plan.opens_at
    due_at   = task_plan.due_at || (task_plan.opens_at + 1.week)

    task = Tasks::CreateTask[task_plan: task_plan,
                             task_type: 'reading',
                             title:     title,
                             opens_at:  opens_at,
                             due_at:    due_at]
    task.save!
    task
  end

  def self.add_core_steps!(task:, cnx_pages:)
    cnx_pages.each do |page|
      page.fragments.each do |fragment|
        step = Tasks::Models::TaskStep.new(task: task, page_id: page.id)

        step.tasked =
          case fragment
          when OpenStax::Cnx::V1::Fragment::ExerciseChoice
            tasked_exercise_choice(exercise_choice_fragment: fragment, step: step)
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
        step.core_group!

        task.task_steps << step
      end
    end
    task.save!
    task
  end

  def self.add_spaced_practice_exercise_steps!(task: task, taskee: taskee)
    k_ago_map = [ [1,1], [2,1] ]
    task.spaced_practice_algorithm = SpacedPracticeAlgorithmIReading.new(k_ago_map: k_ago_map)

    max_num_spaced_practice_steps = k_ago_map.reduce(0) {|result, pair| result += pair.last}
    max_num_spaced_practice_steps.times do
      step = Tasks::Models::TaskStep.new(task: task)
      step.tasked = Tasks::Models::TaskedPlaceholder.new

      step.spaced_practice_group!

      task.task_steps << step
    end

    task.save!
    task
  end

  def self.tasked_reading(reading_fragment:, page:, step: nil)
    Tasks::Models::TaskedReading.new(task_step: step,
                                     url: page.url,
                                     path: page.path,
                                     title: reading_fragment.title,
                                     content: reading_fragment.to_html)
  end

  def self.tasked_exercise_choice(exercise_choice_fragment:, step:)
    exercises = exercise_choice_fragment.exercise_fragments
    tasked_exercise(exercise_fragment: exercises.sample,
                    can_be_recovered: true,
                    step: step)
  end

  def self.tasked_exercise(exercise_fragment:,
                           can_be_recovered: false,
                           step: nil)
    if exercise_fragment.embed_tag.blank?
      logger.warn "Exercise without embed tag found while creating iReading"
      return
    end

    # Search local (cached) Exercises for one matching the embed tag
    exercises = Content::Routines::SearchExercises[
                  tag: exercise_fragment.embed_tag
                ]
    exercise = exercises.first
    TaskExercise[exercise: exercises.first,
                         can_be_recovered: can_be_recovered,
                         task_step: step]
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

  def self.logger
    Rails.logger
  end

end
