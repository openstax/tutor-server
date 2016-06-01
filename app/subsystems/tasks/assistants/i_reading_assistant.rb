class Tasks::Assistants::IReadingAssistant < Tasks::Assistants::FragmentAssistant

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
          },
          "minItems": 1,
          "uniqueItems": true
        }
      },
      "additionalProperties": false
    }'
  end

  def initialize(task_plan:, taskees:)
    super

    @pages = collect_pages
    @ecosystems_map = {}
  end

  def build_tasks
    taskees.map{ |taskee| build_reading_task(pages: @pages, taskee: taskee) }
  end

  protected

  def self.num_personalized_exercises
    1
  end

  def collect_pages
    ecosystem.pages_by_ids(task_plan.settings['page_ids'])
  end

  def build_reading_task(pages:, taskee:)
    task = build_task

    reset_used_exercises

    add_core_steps!(task: task, pages: pages)

    # Don't add dynamic exercises if all the reading dynamic exercise pools are empty
    # This happens, for example, on intro pages
    unless pages.all?{ |page| page.reading_dynamic_pool.exercises.empty? }
      add_spaced_practice_exercise_steps!(task: task, taskee: taskee)
      add_personalized_exercise_steps!(task: task, taskee: taskee)
    end

    task
  end

  def build_task
    title    = task_plan.title || 'iReading'
    description = task_plan.description

    task = Tasks::BuildTask[
      task_plan: task_plan,
      task_type: :reading,
      title:     title,
      description: description
    ]
    AddSpyInfo[to: task, from: ecosystem]
    task
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

  def assign_spaced_practice_exercise(task:, exercise:)
    TaskExercise.call(task: task, exercise: exercise) do |step|
      step.group_type = :spaced_practice_group
      step.add_related_content(exercise.page.related_content)
    end
  end

  def add_spaced_practice_exercise_steps!(task:, taskee:)
    # Get taskee's reading history
    history = GetHistory.call(role: taskee, type: :reading, current_task: task).outputs

    core_exercise_numbers = history.exercises.first.map(&:number)

    course = task_plan.owner

    spaced_practice_status = []

    self.class.k_ago_map.each do |k_ago, num_requested|
      # Not enough history
      if k_ago >= history.tasks.size
        spaced_practice_status << "Not enough tasks in history to fill the #{k_ago}-ago slot"
        next
      end

      spaced_ecosystem = history.ecosystems[k_ago]

      # Get pages from the TaskPlan settings
      spaced_task = history.tasks[k_ago]
      page_ids = spaced_task.task_plan.settings['page_ids']
      spaced_pages = spaced_ecosystem.pages_by_ids(page_ids)

      # Reuse Ecosystems map when possible
      @ecosystems_map[spaced_ecosystem.id] ||= Content::Map.find(
        from_ecosystems: [spaced_ecosystem, ecosystem].uniq, to_ecosystem: ecosystem
      )

      # Map the pages to exercises in the new ecosystem
      spaced_exercises = @ecosystems_map[spaced_ecosystem.id].map_pages_to_exercises(
        pages: spaced_pages, pool_type: :reading_dynamic
      ).values.flatten.uniq

      filtered_exercises = FilterExcludedExercises[
        exercises: spaced_exercises, course: course,
        additional_excluded_numbers: core_exercise_numbers
      ]

      chosen_exercises = ChooseExercises[
        exercises: filtered_exercises, count: num_requested, history: history
      ]

      # Set related_content and add the exercises to the task
      chosen_exercises.each do |chosen_exercise|
        assign_spaced_practice_exercise(task: task, exercise: chosen_exercise)
      end

      spaced_practice_status << "Could not completely fill the #{k_ago}-ago slot" \
        if chosen_exercises.size < num_requested
    end

    spaced_practice_status << 'Completely filled' if spaced_practice_status.empty?

    AddSpyInfo[to: task, from: { spaced_practice: spaced_practice_status }]

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

end
