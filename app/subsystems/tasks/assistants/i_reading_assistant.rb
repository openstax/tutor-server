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
                             due_at:    due_at,
                             feedback_at: Time.now]
    task.save!
    task
  end

  def self.add_core_steps!(task:, cnx_pages:)
    cnx_pages.each do |page|
      # Chapter intro pages get their titles from the chapter instead
      title = page.is_intro? ? page.book_part_title : page.title

      page.fragments.each do |fragment|
        step = Tasks::Models::TaskStep.new(task: task)

        case fragment
        when OpenStax::Cnx::V1::Fragment::ExerciseChoice
          tasked_exercise_choice(exercise_choice_fragment: fragment, step: step, title: title)
        when OpenStax::Cnx::V1::Fragment::Exercise
          tasked_exercise(exercise_fragment: fragment, step: step, title: title)
        when OpenStax::Cnx::V1::Fragment::Video
          tasked_video(video_fragment: fragment, step: step, title: title)
        when OpenStax::Cnx::V1::Fragment::Interactive
          tasked_interactive(interactive_fragment: fragment, step: step, title: title)
        else
          tasked_reading(reading_fragment: fragment, page: page, title: title, step: step)
        end

        next if step.tasked.nil?
        step.core_group!

        task.task_steps << step

        # Only the first step for each Page should have a title
        title = nil
      end
    end

    task.save!
    task
  end

  def self.add_spaced_practice_exercise_steps!(task:, taskee:)
    ireading_history = get_taskee_ireading_history(task: task, taskee: taskee)
    #puts "taskee: #{taskee.inspect}"
    #puts "ireading history:  #{ireading_history.inspect}"

    exercise_history = get_exercise_history(tasks: ireading_history)
    #puts "exercise history:  #{exercise_history.collect{|ex| ex.id}.sort}"

    exercise_pools = get_exercise_pools(tasks: ireading_history)
    #puts "exercise pools:  #{exercise_pools.map{|ep| ep.collect{|ex| ex.id}.sort}}}"

    self.k_ago_map.each do |k_ago, number|
      break if k_ago >= exercise_pools.count

      candidate_exercises = (exercise_pools[k_ago] - exercise_history).sort_by{|ex| ex.id}.take(10)

      number.times do
        #puts "candidate_exercises: #{candidate_exercises.collect{|ex| ex.id}.sort}"
        #puts "exercise history:    #{exercise_history.collect{|ex| ex.id}.sort}"

        chosen_exercise = candidate_exercises.first #sample
        #puts "chosen exercise:     #{chosen_exercise.id}"

        candidate_exercises.delete(chosen_exercise)
        exercise_history.push(chosen_exercise)

        step = add_exercise_step(task: task, exercise: chosen_exercise)
        step.spaced_practice_group!
      end
    end

    task.save!
    task
  end

  def self.get_taskee_ireading_history(task:, taskee:)
    tasks = Tasks::Models::Task.joins{taskings}.
                                where{taskings.entity_role_id == taskee.id}

    ireading_history = tasks.
                         select{|tt| tt.reading?}.
                         reject{|tt| tt == task}.
                         sort_by{|tt| tt.due_at}.
                         push(task).
                         reverse

    ireading_history
  end

  def self.get_exercise_history(tasks:)
    exercise_history = tasks.collect do |task|
      exercise_steps = task.task_steps.select{|task_step| task_step.exercise?}
      content_exercises = exercise_steps.collect do |ex_step|
        content_exercise = Content::Models::Exercise.where{url == ex_step.tasked.url}
      end
      content_exercises
    end.flatten.compact
    exercise_history
  end

  def self.get_exercise_pools(tasks:)
    exercise_pools = tasks.collect do |task|
      page_ids = task.task_plan.settings['page_ids']
      content_pages = Content::Models::Page.find(page_ids)
      los = content_pages.collect do |page|
        page_los = page.page_tags.select{|page_tag| page_tag.tag.lo?}
                                 .collect{|page_tag| page_tag.tag.value}
        page_los
      end.flatten.compact.uniq

      exercises = Content::Models::Exercise.joins{exercise_tags.tag}.
                                            where{exercise_tags.tag.value.in los}.
                                            uniq
      exercises = exercises.select do |ex|
        ex.exercise_tags.detect do |ex_tag|
          ['practice-problem', 'practice-concepts'].include?(ex_tag.tag.value)
        end
      end

      exercises
    end
    exercise_pools
  end

  def self.k_ago_map
    k_ago_map = [ [1,1], [2,1] ]
  end

  def self.add_exercise_step(task:, exercise:)
    step = Tasks::Models::TaskStep.new(task: task)
    TaskExercise[task_step: step, exercise: exercise]
    task.task_steps << step
    step
  end

  def self.tasked_reading(reading_fragment:, page:, step:, title: nil)
    Tasks::Models::TaskedReading.new(task_step: step,
                                     url: page.url,
                                     chapter_section: page.chapter_section,
                                     title: title,
                                     content: reading_fragment.to_html)
  end

  def self.tasked_exercise_choice(exercise_choice_fragment:, step:, title: nil)
    exercises = exercise_choice_fragment.exercise_fragments
    tasked_exercise(exercise_fragment: exercises.sample,
                    step: step,
                    can_be_recovered: true,
                    title: title)
  end

  def self.tasked_exercise(exercise_fragment:,
                           step:,
                           can_be_recovered: false,
                           title: nil)
    if exercise_fragment.embed_tag.blank?
      logger.warn "Exercise without embed tag found while creating iReading"
      return
    end

    # Search local (cached) Exercises for one matching the embed tag
    exercises = Content::Routines::SearchExercises[
                  tag: exercise_fragment.embed_tag
                ]
    exercise = exercises.first
    TaskExercise[exercise: exercises.first, title: title,
                 can_be_recovered: can_be_recovered, task_step: step]
  end

  def self.tasked_video(video_fragment:, step:, title: nil)
    if video_fragment.url.blank?
      logger.warn "Video without embed tag found while creating iReading"
      return
    end

    Tasks::Models::TaskedVideo.new(task_step: step,
                                   url: video_fragment.url,
                                   title: title,
                                   content: video_fragment.to_html)
  end

  def self.tasked_interactive(interactive_fragment:, step:, title: nil)
    if interactive_fragment.url.blank?
      logger.warn('Interactive without iframe found while creating iReading')
      return
    end

    Tasks::Models::TaskedInteractive.new(task_step: step,
                                         url: interactive_fragment.url,
                                         title: title,
                                         content: interactive_fragment.to_html)
  end

  def self.logger
    Rails.logger
  end

end
