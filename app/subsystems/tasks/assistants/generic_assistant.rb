# The generic assistant is a base class for other assistants to inherit from
# It's not intended for direct use
# since it does not implement the all-important `build_tasks` method
class Tasks::Assistants::GenericAssistant
  def initialize(task_plan:, individualized_tasking_plans:)
    @task_plan = task_plan
    @individualized_tasking_plans = individualized_tasking_plans

    @ecosystems_map = {}
    @page_cache = {}
    @exercise_cache = Hash.new { |hash, key| hash[key] = Hash.new { |hash, key| hash[key] = {} } }
    @pool_exercise_cache = Hash.new { |hash, key| hash[key] = {} }
  end

  protected

  attr_reader :task_plan, :individualized_tasking_plans

  def ecosystem
    task_plan.ecosystem
  end

  def get_spaced_ecosystems_map(spaced_ecosystem_id:)
    # Reuse Ecosystems map when possible
    @ecosystems_map[spaced_ecosystem_id] ||= begin
      spaced_ecosystem = Content::Models::Ecosystem.find(spaced_ecosystem_id)

      Content::Map.find_or_create_by(
        from_ecosystems: [spaced_ecosystem, ecosystem].uniq, to_ecosystem: ecosystem
      )
    end
  end

  def reset_used_exercises
    @used_exercise_numbers = Set.new
  end

  def add_exercise_step!(
    task:, exercise:, group_type:, is_core:, title: nil, labels: nil, spy: nil, fragment_index: nil
  )
    labels ||= []
    spy ||= {}
    @used_exercise_numbers << exercise.number

    TaskExercise.call(
      task: task,
      exercise: exercise,
      title: title,
      group_type: group_type,
      is_core: is_core,
      labels: labels,
      spy: spy,
      fragment_index: fragment_index
    ).outputs.task_step
  end

  def get_all_page_exercises_with_queries(page:, queries:)
    (queries || []).flat_map do |field, values|
      sorted_values = [values].flatten.uniq.sort

      @exercise_cache[page.id][field][sorted_values] ||= case field.to_sym
      when :tag
        ecosystem.exercises.joins(:tags).where(
          content_page_id: page.id, tags: { value: sorted_values }
        )
      when :nickname
        ecosystem.exercises.where(content_page_id: page.id, nickname: sorted_values)
      else
        raise NotImplementedError
      end
    end
  end

  def get_pool_exercises(page:, pool_type:)
    pool_method = "#{pool_type}_exercise_ids".to_sym

    @pool_exercise_cache[page.id][pool_type] ||= page.exercises.where(id: page.send(pool_method))
  end

  def get_unused_page_exercises_with_queries(page:, queries:)
    raise 'You must call reset_used_exercises before get_unused_page_exercises_with_queries' \
      if @used_exercise_numbers.nil?

    exercises = get_all_page_exercises_with_queries(page: page, queries: queries)

    exercises.reject { |ex| @used_exercise_numbers.include?(ex.number) }
  end

  def get_unused_pool_exercises(page:, pool_type:)
    raise 'You must call reset_used_exercises before get_unused_pool_exercises' \
      if @used_exercise_numbers.nil?

    exercises = get_pool_exercises(page: page, pool_type: pool_type)

    exercises.reject { |ex| @used_exercise_numbers.include?(ex.number) }
  end

  # Limits the history to tasks due before the given task's due date
  # Adds the given task to the history
  def history_for_task(task:, core_page_ids:, history:)
    history = history.dup

    task_sort_array = [task.due_at, task.opens_at, task.closes_at, task.created_at, task.id]

    history_indices = 0.upto(history.total_count)
    history_indices_to_keep = history_indices.select do |index|
      ([history.due_ats[index], history.opens_ats[index], history.closes_ats[index],
        history.created_ats[index], history.task_ids[index]] <=> task_sort_array) == -1
    end

    # Remove tasks due after the given task from the history
    history.total_count = history_indices_to_keep.size
    history.task_ids = history.task_ids.values_at(*history_indices_to_keep)
    history.task_types = history.task_types.values_at(*history_indices_to_keep)
    history.ecosystem_ids = history.ecosystem_ids.values_at(*history_indices_to_keep)
    history.core_page_ids = history.core_page_ids.values_at(*history_indices_to_keep)
    history.exercise_numbers = history.exercise_numbers.values_at(*history_indices_to_keep)
    history.created_ats = history.created_ats.values_at(*history_indices_to_keep)
    history.opens_ats = history.opens_ats.values_at(*history_indices_to_keep)
    history.due_ats = history.due_ats.values_at(*history_indices_to_keep)
    history.closes_ats = history.closes_ats.values_at(*history_indices_to_keep)

    # Add the given task to the history
    tasked_exercises = task.task_steps.select(&:exercise?).map(&:tasked)
    exercise_numbers = tasked_exercises.map{ |te| te.exercise.number }

    history.total_count += 1
    history.task_ids.unshift task.id
    history.task_types.unshift task.task_type.to_sym
    history.ecosystem_ids.unshift task_plan.ecosystem.id
    history.core_page_ids.unshift core_page_ids
    history.exercise_numbers.unshift exercise_numbers
    history.created_ats.unshift task.created_at
    history.opens_ats.unshift task.opens_at
    history.due_ats.unshift task.due_at
    history.closes_ats.unshift task.closes_at

    history
  end

  def get_pages(page_ids:)
    page_ids = [page_ids].flatten
    cached_page_ids = @page_cache.keys
    uncached_page_ids = page_ids - cached_page_ids

    unless uncached_page_ids.empty?
      pages = Content::Models::Page.where(id: uncached_page_ids)
      pages.each { |page| @page_cache[page.id] = page }
    end

    @page_cache.values_at(*page_ids)
  end

  def build_task(type:, default_title:, individualized_tasking_plan:)
    role = individualized_tasking_plan.target

    Tasks::Models::Task.new(
      task_plan:   task_plan,
      course:      task_plan.course,
      ecosystem:   ecosystem,
      task_type:   type,
      title:       task_plan.title || default_title,
      description: task_plan.description,
      opens_at:    individualized_tasking_plan.opens_at,
      due_at:      individualized_tasking_plan.due_at,
      closes_at:   individualized_tasking_plan.closes_at
    ).tap do |task|
      task.taskings << Tasks::Models::Tasking.new(task: task, role: role)
      AddSpyInfo[to: task, from: ecosystem]
    end
  end

  def add_placeholder_steps!(task:, group_type:, is_core:, count:, labels: [], page: nil)
    count.times do
      task_step = Tasks::Models::TaskStep.new(task: task, labels: labels, page: page)
      tasked_placeholder = Tasks::Models::TaskedPlaceholder.new(task_step: task_step)
      tasked_placeholder.placeholder_type = :exercise_type
      task_step.tasked = tasked_placeholder
      task_step.group_type = group_type
      task_step.is_core = is_core
      task.task_steps << task_step
    end

    task
  end
end
