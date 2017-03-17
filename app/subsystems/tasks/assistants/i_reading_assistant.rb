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

    @non_dynamic_pages, @dynamic_pages = @pages.partition do |page|
      page.reading_dynamic_pool.empty?
    end
  end

  def build_tasks
    roles = individualized_tasking_plans.map(&:target)
    histories = GetHistory[roles: roles, type: :reading]

    individualized_tasking_plans.map do |tasking_plan|
      build_reading_task(history: histories[tasking_plan.target],
                         individualized_tasking_plan: tasking_plan)
    end
  end

  protected

  def num_personalized_exercises_per_page
    3
  end

  def num_spaced_practice_exercises_per_page
    2
  end

  def build_reading_task(history:, individualized_tasking_plan:)
    task = build_task(
      type: :reading,
      default_title: 'Reading',
      individualized_tasking_plan: individualized_tasking_plan
    )

    reset_used_exercises

    add_core_steps!(task: task, history: history)

    # If only intro pages are assigned, we choose not to include the assignment in the history
    # In that case, this assignment itself should also not include spaced practice
    # This happens, for example, if only intro pages are assigned
    add_placeholder_steps!(
      task: task,
      group_type: :spaced_practice_group,
      count: num_spaced_practice_exercises_per_page * @dynamic_pages.size + 1
    ) unless @dynamic_pages.empty?

    task
  end

  def add_core_steps!(task:, history:)
    course = task_plan.owner

    @pages.each do |page|
      # Chapter intro pages get their titles from the chapter instead
      page_title = page.is_intro? ? page.chapter.title : page.title
      related_content = page.related_content(title: page_title)

      # Reading content
      task_fragments(
        task: task,
        fragments: page.fragments,
        page_title: page_title,
        page: page,
        related_content: related_content
      )

      # Personalized exercises after each page
      # Don't add dynamic exercises if all the reading dynamic exercise pools are empty
      # This happens, for example, on intro pages
      add_placeholder_steps!(
        task: task,
        group_type: :personalized_group,
        count: num_personalized_exercises_per_page
      ) unless @non_dynamic_pages.include?(page)
    end

    task
  end

end
