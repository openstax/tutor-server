class Tasks::Assistants::IReadingAssistant < Tasks::Assistants::FragmentAssistant
  NUM_PES_PER_CORE_PAGE = 3
  NUM_SPES = 3

  def self.schema
    '{
      "type": "object",
      "properties": {
        "page_ids": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "minItems": 0,
          "uniqueItems": true
        }
      },
      "required": [
        "page_ids"
      ],
      "additionalProperties": false
    }'
  end

  def initialize(task_plan:, individualized_tasking_plans:)
    super

    page_ids = task_plan.core_page_ids.map(&:to_i)
    pages_by_id = ecosystem.pages.where(id: page_ids).index_by(&:id)
    @pages = pages_by_id.values_at(*page_ids).compact

    @page_ids_with_teacher_exercises = Set.new(
      Content::Models::Exercise.where(
        content_page_id: @pages.map(&:id), user_profile_id: course.related_teacher_profile_ids
      ).pluck(:content_page_id)
    )
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
      is_core: false,
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
        page_title: page.title,
        page: page
      )

      # Personalized exercises after each page

      # Don't add dynamic exercises if all the reading dynamic exercise pools are empty
      # This happens, for example, on intro pages
      next if !@page_ids_with_teacher_exercises.include?(page.id) &&
              page.reading_dynamic_exercise_ids.empty?

      add_placeholder_steps!(
        task: task,
        group_type: :personalized_group,
        is_core: true,
        count: num_pes_per_core_page,
        page: page
      )
    end

    task
  end
end
