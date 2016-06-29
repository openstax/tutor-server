# The generic assistant is a base class for other assistants to inherit from
# It's not intended for direct use
# since it does not implement the all-important `build_tasks` method
class Tasks::Assistants::GenericAssistant

  def initialize(task_plan:, roles:)
    @task_plan = task_plan
    @roles = roles
    @ecosystems_map = {}
    @page_cache = {}
    @exercise_cache = Hash.new{ |hash, key| hash[key] = {} }
    @spaced_exercise_cache = Hash.new{ |hash, key| hash[key] = {} }
    reset_used_exercises
  end

  protected

  attr_reader :task_plan, :roles

  def ecosystem
    return @ecosystem unless @ecosystem.nil?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(task_plan.ecosystem)
    @ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)
  end

  def map_spaced_ecosystem_id_to_ecosystem(spaced_ecosystem_id)
    # Reuse Ecosystems map when possible
    return @ecosystems_map[spaced_ecosystem_id] if @ecosystems_map.has_key?(spaced_ecosystem_id)

    spaced_ecosystem = Content::Ecosystem.find(spaced_ecosystem_id)

    Content::Map.find_or_create_by(
      from_ecosystems: [spaced_ecosystem, ecosystem].uniq, to_ecosystem: ecosystem
    )
  end

  def get_all_page_exercises_with_tags(page, tags)
    sorted_tags = [tags].flatten.uniq.sort

    @exercise_cache[page.id][sorted_tags] ||= ecosystem.exercises_with_tags(
      sorted_tags, pages: page
    )
  end

  def reset_used_exercises
    @used_exercise_numbers = []
  end

  def get_random_unused_page_exercise_with_tags(page, tags)
    raise 'You must call reset_used_exercises before get_random_unused_page_exercise_with_tags' \
      if @used_exercise_numbers.nil?

    exercises = get_all_page_exercises_with_tags(page, tags)

    candidate_exercises = exercises.reject do |ex|
      @used_exercise_numbers.include?(ex.number)
    end

    candidate_exercises.sample.tap do |chosen_exercise|
      @used_exercise_numbers << chosen_exercise.number unless chosen_exercise.nil?
    end
  end

  def add_current_task_to_individual_history(task:, core_page_ids:, history:)
    ecosystem_id = task_plan.ecosystem.id
    exercise_steps = task.task_steps.select(&:exercise?)
    tasked_exercises = exercise_steps.map(&:tasked)
    exercise_numbers = tasked_exercises.map{ |te| te.exercise.number }

    history.total_count += 1
    history.ecosystem_ids.unshift ecosystem_id
    history.core_page_ids.unshift core_page_ids
    history.exercise_numbers.unshift exercise_numbers

    history
  end

  def get_pages(page_ids, already_sorted: false)
    page_ids = [page_ids].flatten.uniq.sort unless already_sorted
    return @page_cache[page_ids] if @page_cache.has_key?(page_ids)

    page_models = Content::Models::Page.where(id: page_ids)
    pages = page_models.map{ |model| Content::Page.new(strategy: model.wrap) }

    @page_cache[page_ids] = pages
  end

  def build_task(type:, default_title:)
    title    = task_plan.title || default_title
    description = task_plan.description

    task = Tasks::BuildTask[
      task_plan:   task_plan,
      task_type:   type,
      title:       title,
      description: description
    ].tap{ |task| AddSpyInfo[to: task, from: ecosystem] }
  end

  def assign_spaced_practice_exercise(task:, exercise:)
    TaskExercise.call(task: task, exercise: exercise) do |step|
      step.group_type = :spaced_practice_group
      step.add_related_content(exercise.page.related_content)
    end
  end

  def add_spaced_practice_exercise_steps!(task:, core_page_ids:, history:, k_ago_map:, pool_type:)
    history = add_current_task_to_individual_history(
      task: task, core_page_ids: core_page_ids, history: history
    )

    core_exercise_numbers = history.exercise_numbers.first

    course = task_plan.owner

    spaced_practice_status = []

    k_ago_map.each do |k_ago, number|
      # Not enough history
      if k_ago >= history.total_count
        spaced_practice_status << "Not enough tasks in history to fill the #{k_ago}-ago slot"
        next
      end

      spaced_ecosystem_id = history.ecosystem_ids[k_ago]
      sorted_spaced_page_ids = history.core_page_ids[k_ago].uniq.sort

      @spaced_exercise_cache[spaced_ecosystem_id][sorted_spaced_page_ids] ||= begin
        # Get the ecosystems map
        ecosystems_map = map_spaced_ecosystem_id_to_ecosystem(spaced_ecosystem_id)

        # Get core pages from the history
        spaced_pages = get_pages(sorted_spaced_page_ids, already_sorted: true)

        # Map the pages to exercises in the new ecosystem
        ecosystems_map.map_pages_to_exercises(
          pages: spaced_pages, pool_type: pool_type
        ).values.flatten.uniq
      end

      filtered_exercises = FilterExcludedExercises[
        exercises: @spaced_exercise_cache[spaced_ecosystem_id][sorted_spaced_page_ids],
        course: course, additional_excluded_numbers: core_exercise_numbers
      ]

      chosen_exercises = ChooseExercises[
        exercises: filtered_exercises, count: number, history: history
      ]

      # Set related_content and add the exercises to the task
      chosen_exercises.each do |chosen_exercise|
        assign_spaced_practice_exercise(task: task, exercise: chosen_exercise)
      end

      spaced_practice_status << "Could not completely fill the #{k_ago}-ago slot" \
        if chosen_exercises.size < number
    end

    spaced_practice_status << 'Completely filled' if spaced_practice_status.empty?

    AddSpyInfo[to: task, from: { spaced_practice: spaced_practice_status }]

    task
  end

  def add_personalized_exercise_steps!(task:, num_personalized_exercises:,
                                       personalized_placeholder_strategy_class:)
    return task if num_personalized_exercises == 0

    task.personalized_placeholder_strategy = personalized_placeholder_strategy_class.new

    num_personalized_exercises.times do
      task_step = Tasks::Models::TaskStep.new(task: task)
      tasked_placeholder = Tasks::Models::TaskedPlaceholder.new(task_step: task_step)
      tasked_placeholder.placeholder_type = :exercise_type
      task_step.tasked = tasked_placeholder
      task_step.group_type = :personalized_group
      task.add_step(task_step)
    end

    task
  end

end
