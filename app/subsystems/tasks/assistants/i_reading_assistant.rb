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

  def initialize(task_plan:, individualized_tasking_plans:)
    super

    @pages = ecosystem.pages_by_ids(task_plan.settings['page_ids'])
  end

  def build_tasks
    # Don't add dynamic exercises if all the reading dynamic exercise pools are empty
    # This happens, for example, on intro pages
    reading_dynamic_pools = ecosystem.reading_dynamic_pools(pages: @pages)
    skip_dynamic = reading_dynamic_pools.all?(&:empty?)

    roles = individualized_tasking_plans.map(&:target)
    histories = GetHistory[roles: roles, type: :reading]

    individualized_tasking_plans.map do |tasking_plan|
      build_reading_task(pages: @pages, history: histories[tasking_plan.target],
                         individualized_tasking_plan: tasking_plan, skip_dynamic: skip_dynamic)
    end
  end

  protected

  def num_personalized_exercises_per_page
    3
  end

  ## Entries in the list have the form:
  ##   [from-this-many-events-ago, choose-this-many-exercises]
  def k_ago_map
    [ [2, 1], [4, 1] ]
  end

  ## Entries in the list have the form:
  ##   [nil, choose-this-many-exercises]
  def random_ago_map
    [ [nil, 1] ]
  end

  def build_reading_task(pages:, history:, individualized_tasking_plan:, skip_dynamic:)
    task = build_task(type: :reading, default_title: 'Reading',
                      individualized_tasking_plan: individualized_tasking_plan)

    reset_used_exercises

    add_core_steps!(task: task, pages: pages, history: history)

    unless skip_dynamic
      add_spaced_practice_exercise_steps!(
        task: task, core_page_ids: @pages.map(&:id), pool_type: :reading_dynamic,
        history: history, k_ago_map: k_ago_map, for_each_core_page: true
      )

      add_spaced_practice_exercise_steps!(
        task: task, core_page_ids: @pages.map(&:id), pool_type: :reading_dynamic,
        history: history, k_ago_map: random_ago_map, for_each_core_page: false
      )
    end

    task
  end

  def add_core_steps!(task:, pages:, history:)
    course = task_plan.owner

    pages.each do |page|
      # Chapter intro pages get their titles from the chapter instead
      page_title = page.is_intro? ? page.chapter.title : page.title
      related_content = page.related_content(title: page_title)

      # Reading content
      task_fragments(task: task, fragments: page.fragments,
                     page_title: page_title, page: page, related_content: related_content)

      # "Personalized" exercises after each page
      candidate_exercises = get_unused_pool_exercises page: page, pool_type: :reading_dynamic

      filtered_exercises = FilterExcludedExercises[
        exercises: candidate_exercises, course: course,
        additional_excluded_numbers: @used_exercise_numbers
      ]

      chosen_exercises = ChooseExercises[
        exercises: filtered_exercises, count: num_personalized_exercises_per_page, history: history
      ]

      chosen_exercises.each do |exercise|
        add_exercise_step!(task: task, exercise: exercise, group_type: :personalized_group)
      end
    end

    task
  end

end
