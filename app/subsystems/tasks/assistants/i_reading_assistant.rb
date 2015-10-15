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
    @ecosystems_map = {}
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
    # Get taskee's reading history
    history = GetHistory.call(role: taskee, type: :reading, current_task: task).outputs

    all_worked_exercise_numbers = history.exercises.flatten.collect{ |ex| ex.number }

    self.class.k_ago_map.each do |k_ago, number|
      # Not enough history
      break if k_ago >= history.tasks.size

      spaced_ecosystem = history.ecosystems[k_ago]

      # Get pages from the TaskPlan settings
      spaced_task = history.tasks[k_ago]
      page_ids = spaced_task.task_plan.settings['page_ids']
      spaced_pages = spaced_ecosystem.pages_by_ids(page_ids)

      # Reuse Ecosystems map when possible
      @ecosystems_map[spaced_ecosystem.id] ||= Content::Map.find(
        from_ecosystems: [spaced_ecosystem, @ecosystem].uniq, to_ecosystem: @ecosystem
      )

      # Map the pages to exercises in the new ecosystem
      spaced_exercises = @ecosystems_map[spaced_ecosystem.id].map_pages_to_exercises(
        pages: spaced_pages, pool_type: :reading_dynamic
      )

      # Exclude exercises already worked (by number)
      candidate_exercises = spaced_exercises.values.flatten.uniq.reject do |ex|
        all_worked_exercise_numbers.include?(ex.number)
      end

      # Not enough exercises
      break if candidate_exercises.size < number

      # Randomize and grab the required number of exercises
      chosen_exercises = candidate_exercises.shuffle.first(number)

      # Set related_content and add the exercise to the task
      chosen_exercises.each do |chosen_exercise|
        related_content = chosen_exercise.page.related_content

        step = add_exercise_step(task: task, exercise: chosen_exercise)
        step.group_type = :spaced_practice_group

        step.add_related_content(related_content)
      end
    end

    task
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

  def logger
    Rails.logger
  end

end
