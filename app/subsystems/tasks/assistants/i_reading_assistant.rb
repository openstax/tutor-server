class Tasks::Assistants::IReadingAssistant < Tasks::Assistants::FragmentAssistant

  NUM_PES_PER_CORE_PAGE = 3
  NUM_SPES = 3

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
    individualized_tasking_plans.map do |tasking_plan|
      task = build_task(
        type: :reading,
        default_title: 'Reading',
        individualized_tasking_plan: tasking_plan
      )

      add_task_steps! task: task, num_pes_per_core_page: NUM_PES_PER_CORE_PAGE, num_spes: NUM_SPES
    end
  end

  protected

  def add_task_steps!(task:, num_pes_per_core_page:, num_spes:)
    reset_used_exercises

    add_core_steps!(task: task, num_pes_per_core_page: num_pes_per_core_page)

    add_placeholder_steps!(
      task: task,
      group_type: :spaced_practice_group,
      count: num_spes,
      labels: [ 'review' ]
    )

    task
  end

  def add_core_steps!(task:, num_pes_per_core_page:)
    @pages.each do |page|
      # Reading content
      task_fragments(
        task: task,
        fragments: page.fragments,
        page_title: page.tutor_title,
        page: page
      )

      # Personalized exercises after each page

      # Don't add dynamic exercises if all the reading dynamic exercise pools are empty
      # This happens, for example, on intro pages
      next if page.reading_dynamic_pool.empty?

      add_placeholder_steps!(
        task: task,
        group_type: :personalized_group,
        count: num_pes_per_core_page,
        page: page
      )
    end

    task
  end

end
