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

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees

    collect_pages

    @tag_exercise = {}
    @exercise_pages = {}
    @page_pools = {}
    @pool_exercises = {}
  end

  def build_tasks
    @taskees.collect do |taskee|
      build_ireading_task(
        taskee: taskee,
        pages:  @pages
      ).entity_task
    end
  end

  protected

  def collect_pages
    @page_ids = @task_plan.settings['page_ids']
    raise "No pages selected" if @page_ids.blank?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(@task_plan.ecosystem)
    @ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)

    @pages = @ecosystem.pages_by_ids(@page_ids)
  end

  def build_ireading_task(pages:, taskee:)
    task = build_task

    add_core_steps!(task: task, pages: pages)
    add_spaced_practice_exercise_steps!(task: task, taskee: taskee)
    add_personalized_exercise_steps!(task: task, taskee: taskee)

    task
  end

  def build_task
    title    = @task_plan.title || 'iReading'
    description = @task_plan.description

    task = Tasks::BuildTask[
      task_plan: @task_plan,
      task_type: :reading,
      title:     title,
      description: description,
      feedback_at: Time.now
    ]
    AddSpyInfo[to: task, from: @ecosystem]
    return task
  end

  def task_fragments(task:, fragments:, fragment_title:, page:, related_content:)
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

        task_fragments(task: task, fragments: subfragments, fragment_title: fragment_title,
                       page: page, related_content: related_content)
      when OpenStax::Cnx::V1::Fragment::ExerciseChoice
        tasked_exercise_choice(exercise_choice_fragment: fragment,
                               step: step, title: fragment_title)
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
      step.add_related_content(page.related_content)
      task.task_steps << step

      # Only the first step for each Page should have a title
      fragment_title = nil
    end
  end

  def add_core_steps!(task:, pages:)
    pages.each do |page|
      # Chapter intro pages get their titles from the chapter instead
      page_title = page.is_intro? ? page.chapter.title : page.title
      related_content = page.related_content(title: page_title)
      task_fragments(task: task, fragments: page.fragments, fragment_title: page_title,
                     page: page, related_content: related_content)
    end

    task
  end

  def add_spaced_practice_exercise_steps!(task:, taskee:)
    ireading_history = get_taskee_ireading_history(task: task, taskee: taskee)
    #puts "taskee: #{taskee.inspect}"
    #puts "ireading history:  #{ireading_history.inspect}"

    exercise_history = GetExerciseHistory[ecosystem: @ecosystem, entity_tasks: ireading_history]
    #puts "exercise history:  #{exercise_history.map(&:uid).sort}"

    exercise_pools = get_exercise_pools(ireading_history: ireading_history)
    #puts "exercise pools:  #{exercise_pools.map{|ep| ep.map(&:uid).sort}}}"

    flat_history = exercise_history.flatten

    self.class.k_ago_map.each do |k_ago, number|
      break if k_ago >= exercise_pools.count

      candidate_exercises = (exercise_pools[k_ago] - flat_history).uniq
      break if candidate_exercises.size < number

      number.times do
        #puts "candidate_exercises: #{candidate_exercises.map(&:uid).sort}"
        #puts "exercise history:    #{exercise_history.map(&:uid).sort}"

        chosen_exercise = candidate_exercises.to_a.sample # .first to aid debug
        #puts "chosen exercise:     #{chosen_exercise.uid}"

        candidate_exercises.delete(chosen_exercise)
        flat_history.push(chosen_exercise)

        step = add_exercise_step(task: task, exercise: chosen_exercise)
        step.add_related_content(chosen_exercise.page.related_content)
        step.group_type = :spaced_practice_group
      end
    end

    task
  end

  # Get the student's reading assignments
  def get_taskee_ireading_history(task:, taskee:)
    tasks = taskee.taskings.preload(task: {task: {task_steps: :tasked}})
                           .collect{ |tasking| tasking.task.task }

    ireading_history = tasks.select{|tt| tt.reading?}
                            .reject{|tt| tt == task}
                            .sort_by{|tt| [tt.due_at, tt.task_plan.created_at]}
                            .push(task)
                            .reverse
                            .collect{|tt| tt.entity_task}

    ireading_history
  end

  # Get the page for each exercise in the student's assignments
  # From each page, get the pool of dynamic reading problems
  def get_exercise_pools(ireading_history:)
    exercise_pools = ireading_history.collect do |entity_task|
      page_ids = entity_task.task.task_plan.settings['page_ids']
      pages = @ecosystem.pages_by_ids(page_ids)
      pools = get_page_pools(pages)
      pools.collect{ |pool| get_pool_exercises(pool) }.flatten
    end
  end

  def self.k_ago_map
    ## Entries in the list have the form:
    ##   [from-this-many-events-ago, choose-this-many-exercises]
    [ [2,1], [4,1] ]
  end

  def add_personalized_exercise_steps!(task:, taskee:)
    task.personalized_placeholder_strategy = Tasks::PlaceholderStrategies::IReadingPersonalized.new \
      if self.class.num_personalized_exercises > 0

    self.class.num_personalized_exercises.times do
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

  def add_exercise_step(task:, exercise:)
    step = Tasks::Models::TaskStep.new(task: task)
    TaskExercise[task_step: step, exercise: exercise]
    task.task_steps << step
    step
  end

  def tasked_reading(reading_fragment:, page:, step:, title: nil)
    Tasks::Models::TaskedReading.new(task_step: step,
                                     url: page.url,
                                     book_location: page.book_location,
                                     title: title,
                                     content: reading_fragment.to_html)
  end

  def tasked_exercise_choice(exercise_choice_fragment:, step:, title: nil)
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

  def tasked_exercise(exercise_fragment:, step:, can_be_recovered: false, title: nil)
    if exercise_fragment.embed_tag.blank?
      logger.warn "Exercise without embed tag found while creating iReading"
      return
    end

    # Search Ecosystem Exercises for one matching the embed tag
    exercise = get_first_tag_exercise(exercise_fragment.embed_tag)

    unless exercise.nil?
      if can_be_recovered
        # Disable recovery if no exercises that can be used for it are found
        pool = exercise.page.reading_try_another_pool
        los = Set.new exercise.los
        aplos = Set.new exercise.aplos
        candidate_exercises = pool.exercises.select do |ex|
          ex != exercise && \
          (ex.los.any?{ |tt| los.include?(tt) } || ex.aplos.any?{ |tt| aplos.include?(tt) })
        end
        can_be_recovered = false if candidate_exercises.empty?
      end

      # Assign the exercise
      TaskExercise[exercise: exercise, title: title,
                   can_be_recovered: can_be_recovered, task_step: step]
    end
  end

  def tasked_video(video_fragment:, step:, title: nil)
    if video_fragment.url.blank?
      logger.warn "Video without embed tag found while creating iReading"
      return
    end

    Tasks::Models::TaskedVideo.new(task_step: step,
                                   url: video_fragment.url,
                                   title: title,
                                   content: video_fragment.to_html)
  end

  def tasked_interactive(interactive_fragment:, step:, title: nil)
    if interactive_fragment.url.blank?
      logger.warn('Interactive without url found while creating iReading')
      return
    end

    Tasks::Models::TaskedInteractive.new(task_step: step,
                                         url: interactive_fragment.url,
                                         title: title,
                                         content: interactive_fragment.to_html)
  end

  def get_first_tag_exercise(tag)
    @tag_exercise[tag] ||= @ecosystem.exercises_with_tags(tag).first
  end

  def get_exercise_pages(ex)
    @exercise_pages[ex.id] ||= ex.page
  end

  def get_page_pools(pages)
    page_ids = pages.collect{ |pg| pg.id }
    @page_pools[page_ids] ||= @ecosystem.reading_dynamic_pools(pages: pages)
  end

  def get_pool_exercises(pool)
    @pool_exercises[pool.uuid] ||= pool.exercises
  end

  def logger
    Rails.logger
  end

end
