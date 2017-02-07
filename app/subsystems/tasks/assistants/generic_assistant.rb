# The generic assistant is a base class for other assistants to inherit from
# It's not intended for direct use
# since it does not implement the all-important `build_tasks` method
class Tasks::Assistants::GenericAssistant

  def initialize(task_plan:, individualized_tasking_plans:)
    @task_plan = task_plan
    @individualized_tasking_plans = individualized_tasking_plans
    role_ids = individualized_tasking_plans.map(&:target_id)

    periods_by_student_role_id = CourseMembership::Models::Period
      .joins(enrollments: :student)
      .where(enrollments: { student: { entity_role_id: role_ids } })
      .select(
        [:id, CourseMembership::Models::Student.arel_table[:entity_role_id]]
      ).index_by(&:entity_role_id)
    periods_by_teacher_student_role_id = CourseMembership::Models::Period
      .select([:id, :entity_teacher_student_role_id])
      .index_by(&:entity_teacher_student_role_id)
    @periods_by_role_id = periods_by_student_role_id.merge(periods_by_teacher_student_role_id)

    @ecosystems_map = {}
    @page_cache = {}
    @tag_exercise_cache = Hash.new{ |hash, key| hash[key] = {} }
    @pool_exercise_cache = Hash.new{ |hash, key| hash[key] = {} }
  end

  protected

  attr_reader :task_plan, :individualized_tasking_plans

  def ecosystem
    return @ecosystem unless @ecosystem.nil?

    ecosystem_strategy = ::Content::Strategies::Direct::Ecosystem.new(task_plan.ecosystem)
    @ecosystem = ::Content::Ecosystem.new(strategy: ecosystem_strategy)
  end

  def get_spaced_ecosystems_map(spaced_ecosystem_id:)
    # Reuse Ecosystems map when possible
    @ecosystems_map[spaced_ecosystem_id] ||= begin
      spaced_ecosystem = Content::Ecosystem.find(spaced_ecosystem_id)

      Content::Map.find_or_create_by(
        from_ecosystems: [spaced_ecosystem, ecosystem].uniq, to_ecosystem: ecosystem
      )
    end
  end

  def reset_used_exercises
    @used_exercise_numbers = Set.new
  end

  def add_exercise_step!(task:, exercise:, group_type:, title: nil, labels: nil)
    related_content = exercise.page.related_content

    @used_exercise_numbers << exercise.number

    TaskExercise.call(task: task, exercise: exercise) do |step|
      step.group_type = group_type
      step.add_related_content(related_content) if related_content.present?
      step.add_labels(labels) if labels.present?
    end.outputs.task_step
  end

  def get_all_page_exercises_with_tags(page:, tags:)
    sorted_tags = [tags].flatten.uniq.sort

    @tag_exercise_cache[page.id][sorted_tags] ||= ecosystem.exercises_with_tags(
      sorted_tags, pages: page
    )
  end

  def get_pool_exercises(page:, pool_type:)
    pool_method = "#{pool_type}_pool".to_sym

    @pool_exercise_cache[page.id][pool_type] ||= page.send(pool_method).exercises
  end

  def get_unused_page_exercises_with_tags(page:, tags:)
    raise 'You must call reset_used_exercises before get_unused_page_exercises_with_tags' \
      if @used_exercise_numbers.nil?

    exercises = get_all_page_exercises_with_tags(page: page, tags: tags)

    exercises.reject{ |ex| @used_exercise_numbers.include?(ex.number) }
  end

  def get_unused_pool_exercises(page:, pool_type:)
    raise 'You must call reset_used_exercises before get_unused_pool_exercises' \
      if @used_exercise_numbers.nil?

    exercises = get_pool_exercises(page: page, pool_type: pool_type)

    exercises.reject{ |ex| @used_exercise_numbers.include?(ex.number) }
  end

  # Limits the history to tasks due before the given task's due date
  # Adds the given task to the history
  def history_for_task(task:, core_page_ids:, history:)
    history = history.dup

    task_sort_array = [task.due_at, task.opens_at, task.created_at, task.id]

    history_indices = 0.upto(history.total_count)
    history_indices_to_keep = history_indices.select do |index|
      ([history.due_ats[index], history.opens_ats[index],
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

    history
  end

  def get_pages(page_ids:)
    page_ids = [page_ids].flatten
    cached_page_ids = @page_cache.keys
    uncached_page_ids = page_ids - cached_page_ids

    unless uncached_page_ids.empty?
      page_models = Content::Models::Page.where(id: uncached_page_ids)
      pages = page_models.map{ |model| Content::Page.new(strategy: model.wrap) }
      pages.each{ |page| @page_cache[page.id] = page }
    end

    @page_cache.values_at(*page_ids)
  end

  def build_task(type:, default_title:, individualized_tasking_plan:)
    role = individualized_tasking_plan.target

    Tasks::BuildTask[
      task_plan:   task_plan,
      task_type:   type,
      title:       task_plan.title || default_title,
      description: task_plan.description,
      time_zone: individualized_tasking_plan.time_zone,
      opens_at: individualized_tasking_plan.opens_at,
      due_at: individualized_tasking_plan.due_at,
      feedback_at: task_plan.is_feedback_immediate ? nil : individualized_tasking_plan.due_at,
      ecosystem: task_plan.ecosystem
    ].tap do |task|
      task.taskings << Tasks::Models::Tasking.new(task: task, role: role,
                                                  period: @periods_by_role_id[role.id])
      AddSpyInfo[to: task, from: ecosystem]
    end
  end

  def filter_and_choose_exercises(exercises:, course:, count:, history:)
    filtered_exercises = FilterExcludedExercises[
      exercises: exercises, course: course,
      additional_excluded_numbers: @used_exercise_numbers
    ]

    ChooseExercises[exercises: filtered_exercises, count: count, history: history]
  end

  def add_spaced_practice_exercise_steps!(task:, core_page_ids:, pool_type:,
                                          history:, k_ago_map:, for_each_core_page: false)
    raise 'You must call reset_used_exercises before add_spaced_practice_exercise_steps!' \
      if @used_exercise_numbers.nil?

    history = history_for_task task: task, core_page_ids: core_page_ids, history: history

    course = task_plan.owner

    spaced_practice_status = []

    k_ago_map.each do |k_ago, number|
      if k_ago.nil?
        num_previous_tasks = history.total_count

        # Skip if no previous tasks
        next if num_previous_tasks == 0

        # Random-ago does not include 0-ago
        k_ago = SecureRandom.random_number(num_previous_tasks - 1) + 1

        k_ago_name = "random:#{k_ago}"
      else
        k_ago_name = k_ago.to_s
      end

      # Not enough history
      if k_ago >= history.total_count
        spaced_practice_status << "Not enough tasks in history to fill the #{k_ago_name}-ago slot"
        next
      end

      spaced_ecosystem_id = history.ecosystem_ids[k_ago]
      spaced_page_ids = history.core_page_ids[k_ago].uniq

      cached_page_ids = @pool_exercise_cache.keys
      uncached_spaced_page_ids = spaced_page_ids - cached_page_ids

      unless uncached_spaced_page_ids.empty?
        # Get the ecosystems map
        ecosystems_map = get_spaced_ecosystems_map(spaced_ecosystem_id: spaced_ecosystem_id)

        # Get the spaced pages
        uncached_spaced_pages = get_pages(page_ids: uncached_spaced_page_ids)

        # Map the pages to exercises in the new ecosystem
        uncached_pool_exercises_by_pages = ecosystems_map.map_pages_to_exercises(
          pages: uncached_spaced_pages, pool_type: pool_type
        )

        uncached_pool_exercises_by_pages.each do |uncached_spaced_page, exercises|
          @pool_exercise_cache[uncached_spaced_page.id][pool_type] = exercises
        end
      end

      dynamic_spaced_page_ids = spaced_page_ids.reject do |spaced_page_id|
        @pool_exercise_cache[spaced_page_id][pool_type].empty?
      end

      chosen_exercises = if for_each_core_page
        dynamic_spaced_page_ids.map do |spaced_page_id|
          candidate_exercises = @pool_exercise_cache[spaced_page_id][pool_type]

          filter_and_choose_exercises(exercises: candidate_exercises, course: course,
                                      count: number, history: history)
        end
      else
        candidate_exercises = dynamic_spaced_page_ids.flat_map do |spaced_page_id|
          @pool_exercise_cache[spaced_page_id][pool_type]
        end

        [filter_and_choose_exercises(exercises: candidate_exercises, course: course,
                                     count: number, history: history)]
      end

      # Set related_content and add the exercises to the task
      chosen_exercises.flatten.map do |chosen_exercise|
        add_exercise_step!(task: task, exercise: chosen_exercise,
                           group_type: :spaced_practice_group)
      end

      spaced_practice_status << "Could not completely fill the #{k_ago_name}-ago slot" \
        if chosen_exercises.any?{ |exercises| exercises.size < number }
    end

    spaced_practice_status << 'Completely filled' if spaced_practice_status.empty?

    AddSpyInfo[to: task, from: { spaced_practice: spaced_practice_status }]

    task
  end

  def add_personalized_exercise_steps!(task:, count:, personalized_placeholder_strategy_class:)
    return task if count == 0

    task.personalized_placeholder_strategy = personalized_placeholder_strategy_class.new

    count.times do
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
