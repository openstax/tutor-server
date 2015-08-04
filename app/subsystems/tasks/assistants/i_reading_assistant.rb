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
            "type": "string"
          }
        }
      },
      "additionalProperties": false
    }'
  end

  def self.build_tasks(task_plan:, taskees:)
    ## NOTE: This implementation isn't particularly robust: failure to distribute to any taskee will
    ##       result in failure to distribute to EVERY taskee (because the entire transaction will be
    ##       rolled back).  Eventually, we will probably want to create an "undistributed" task and
    ##       have per-taskee workers (with per-taskee transactions) build and distribute the tasks.

    pages = collect_pages(task_plan: task_plan)

    taskees.collect do |taskee|
      build_ireading_task(
        task_plan:    task_plan,
        taskee:       taskee,
        pages:        pages
      )
    end
  end

  protected

  def self.collect_pages(task_plan:)
    page_ids = task_plan.settings['page_ids']
    Ecosystem::Page.find(page_ids)
  end

  def self.build_ireading_task(task_plan:, taskee:, pages:)
    task = build_task(task_plan: task_plan)

    set_los(task: task, pages: pages)

    add_core_steps!(task: task, pages: pages)
    add_spaced_practice_exercise_steps!(task: task, taskee: taskee)
    add_personalized_exercise_steps!(task_plan: task_plan, task: task, taskee: taskee)

    task
  end

  def self.set_los(task:, pages:)
    task.los = pages.map(&:los).flatten.uniq
    task.aplos = pages.map(&:aplos).flatten.uniq
    task
  end

  def self.build_task(task_plan:)
    title    = task_plan.title || 'iReading'
    description = task_plan.description

    Tasks::BuildTask[
      task_plan: task_plan,
      task_type: :reading,
      title:     title,
      description: description,
      feedback_at: Time.now
    ]
  end

  def self.task_fragments(task, fragments, fragment_title, page, related_content)
    fragments.each do |fragment|
      step = Tasks::Models::TaskStep.new(task: task)

      case fragment
      when OpenStax::Cnx::V1::Fragment::Feature
        subfragments = fragment.fragments
        exercise_subfragments = subfragments.select(&:exercise?)
        if exercise_subfragments.count > 1
          # Remove all Exercise fragments and replace with an ExerciseChoice
          subfragments = subfragments - exercise_subfragments
          subfragments << OpenStax::Cnx::V1::Fragment::ExerciseChoice.new(
            node: nil, title: nil, exercise_fragments: exercise_subfragments
          )
        end

        task_fragments(task, subfragments, fragment_title, page, related_content)
      when OpenStax::Cnx::V1::Fragment::ExerciseChoice
        tasked_exercise_choice(exercise_choice_fragment: fragment, step: step, title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::Exercise
        tasked_exercise(exercise_fragment: fragment, step: step, title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::Video
        tasked_video(video_fragment: fragment, step: step, title: fragment_title)
      when OpenStax::Cnx::V1::Fragment::Interactive
        tasked_interactive(interactive_fragment: fragment, step: step, title: fragment_title)
      else
        tasked_reading(reading_fragment: fragment, page: page, title: fragment_title, step: step)
      end

      next if step.tasked.nil?
      step.group_type = :core_group
      step.add_labels(fragment.labels)
      step.add_related_content(related_content)
      task.task_steps << step

      # Only the first step for each Page should have a title
      fragment_title = nil
    end
  end

  def self.add_core_steps!(task:, pages:)
    pages.each do |page|
      # Chapter intro pages get their titles from the chapter instead
      page_title = page.is_intro? ? page.chapter.title : page.title
      related_content = page.related_content(title: page_title)
      task_fragments(task, page.fragments, page_title, page, related_content)
    end

    task
  end

  def self.add_spaced_practice_exercise_steps!(task:, taskee:)
    ireading_history = get_taskee_ireading_history(task: task, taskee: taskee)
    #puts "taskee: #{taskee.inspect}"
    #puts "ireading history:  #{ireading_history.inspect}"

    exercise_history = get_exercise_history(tasks: ireading_history)
    #puts "exercise history:  #{exercise_history.map(&:uid).sort}"

    exercise_pools = get_exercise_pools(tasks: ireading_history)
    #puts "exercise pools:  #{exercise_pools.map{|ep| ep.map(&:uid).sort}}}"

    self.k_ago_map.each do |k_ago, number|
      break if k_ago >= exercise_pools.count

      candidate_exercises = (exercise_pools[k_ago] - exercise_history).sort_by{|ex| ex.uid}
      break if candidate_exercises.count < number

      number.times do
        #puts "candidate_exercises: #{candidate_exercises.map(&:uid).sort}"
        #puts "exercise history:    #{exercise_history.map(&:uid).sort}"

        chosen_exercise = candidate_exercises.sample # .first to aid debug
        #puts "chosen exercise:     #{chosen_exercise.uid}"

        candidate_exercises.delete(chosen_exercise)
        exercise_history.push(chosen_exercise)

        step = add_exercise_step(task: task, exercise: chosen_exercise)
        step.add_related_content(chosen_exercise.related_content)
        step.group_type = :spaced_practice_group
      end
    end

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
    # TODO: Do this wrapping somewhere else? Or punt until we have some Task subsystem wrappers?
    tasks.collect do |task|
      exercise_steps = task.task_steps.select{|task_step| task_step.exercise?}
      exercise_steps.collect do |step|
        strategy = Ecosystem::Strategies::Direct::Exercise.new(step.tasked.exercise)
        Ecosystem::Exercise.new(strategy: strategy)
      end
    end.flatten.compact
  end

  def self.get_exercise_pools(tasks:)
    # TODO: Replace with actual exercise pools
    exercise_pools = tasks.collect do |task|
      pages = collect_pages(task_plan: task.task_plan)
      page_los = pages.collect{ |page| page.los + page.aplos }

      page_exercises = Content::Routines::SearchExercises[tag: page_los, match_count: 1]
      page_exercise_ids = page_exercises.pluck(:id)
      page_exercise_relation = Content::Models::Exercise.where(id: page_exercise_ids)

      phys_tags = ['k12phys', 'os-practice-concepts']
      phys_exercises = Content::Routines::SearchExercises[relation: page_exercise_relation,
                                                          tag: phys_tags,
                                                          match_count: 2]

      bio_tags = ['apbio', 'ost-chapter-review', 'review', 'time-short']
      bio_exercises = Content::Routines::SearchExercises[relation: page_exercise_relation,
                                                         tag: bio_tags,
                                                         match_count: 4]

      combined = [phys_exercises, bio_exercises].flatten.uniq.to_a
      combined
    end
    exercise_pools.collect do |exercise_pool|
      exercise_pool.collect do |content_exercise|
        strategy = Ecosystem::Strategies::Direct::Exercise.new(content_exercise)
        Ecosystem::Exercise.new(strategy: strategy)
      end
    end
  end

  def self.k_ago_map
    ## Entries in the list have the form:
    ##   [from-this-many-events-ago, choose-this-many-exercises]
    [ [2,1], [4,1] ]
  end

  def self.add_personalized_exercise_steps!(task_plan: task_plan, task: task, taskee: taskee)
    task.personalized_placeholder_strategy = Tasks::PlaceholderStrategies::IReadingPersonalized.new \
      if num_personalized_exercises > 0

    num_personalized_exercises.times do
      task_step = Tasks::Models::TaskStep.new(task: task)
      tasked_placeholder = Tasks::Models::TaskedPlaceholder.new(task_step: task_step)
      tasked_placeholder.placeholder_type = :exercise_type
      task_step.tasked = tasked_placeholder
      task_step.group_type = :personalized_group
      task.task_steps << task_step
    end

    task
  end

  def self.num_personalized_exercises
    1
  end

  def self.related_content_for_page(page:, title: page.title)
    { title: title, chapter_section: page.chapter_section }
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
    if exercises.empty?
      logger.warn "Exercise Choice without Exercises found while creating iReading"
      return
    end

    chosen_exercise = exercises.sample
    case chosen_exercise
    when OpenStax::Cnx::V1::Fragment::Exercise
      tasked_exercise(exercise_fragment: chosen_exercise, step: step,
                      can_be_recovered: true, title: title)
    when OpenStax::Cnx::V1::Fragment::ExerciseChoice
      tasked_exercise_choice(exercise_choice_fragment: chosen_exercise, step: step, title: title)
    else
      logger.warn "Exercise Choice with invalid Exercise fragment found while creating iReading"
    end
  end

  def self.tasked_exercise(exercise_fragment:, step:, can_be_recovered: false, title: nil)
    if exercise_fragment.embed_tag.blank?
      logger.warn "Exercise without embed tag found while creating iReading"
      return
    end

    # TODO: Replace with actual exercise pools
    # Search local (cached) Exercises for one matching the embed tag
    exercises = Content::Routines::SearchExercises[tag: exercise_fragment.embed_tag]
    if exercise = exercises.first
      strategy = Ecosystem::Strategies::Direct::Exercise.new(exercise)
      exercise = Ecosystem::Exercise.new(strategy: strategy)
      TaskExercise[exercise: exercise, title: title,
                   can_be_recovered: can_be_recovered, task_step: step]
    end
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
      logger.warn('Interactive without url found while creating iReading')
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
