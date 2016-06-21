# The generic assistant is a base class for other assistants to inherit from
# It's not intended for direct use
# since it does not implement the all-important `build_tasks` method
class Tasks::Assistants::GenericAssistant

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
    @ecosystems_map = {}
    @exercise_cache = {}
    @page_cache = {}
    reset_used_exercises
  end

  protected

  attr_reader :task_plan, :taskees

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

    @exercise_cache[page.id] ||= {}
    @exercise_cache[page.id][sorted_tags] ||= ecosystem.exercises_with_tags(sorted_tags,
                                                                            pages: page)
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

  def get_pages(page_ids)
    return @page_cache[page_ids] if @page_cache.has_key?(page_ids)

    page_models = Content::Models::Page.where(id: page_ids)
    pages = page_models.map{ |model| Content::Page.new(strategy: model.wrap) }

    @page_cache[page_ids] = pages
  end

end
