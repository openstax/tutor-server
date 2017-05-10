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

    tasks = individualized_tasking_plans.map do |tasking_plan|
      build_task(
        type: :reading,
        default_title: 'Reading',
        individualized_tasking_plan: tasking_plan
      )
    end

    # Get the number of personalized steps for each page of each task
    course = task_plan.owner
    core_page_ids = task_plan.settings['page_ids'].map(&:to_i)

    # TODO: PEs for preview assignments (teacher_students)
    student_tasks = tasks.select do |task|
      task.taskings.any? { |tasking| tasking.role.student.present? }
    end

    if student_tasks.empty?
      pes_by_request = {}
      spes_by_request = {}
    else
      create_requests = student_tasks.map do |task|
        { course: course, task: task, core_page_ids: core_page_ids }
      end
      OpenStax::Biglearn::Api.create_update_assignments create_requests, perform_later: false

      ex_requests = student_tasks.map { |task| { task: task } }
      pes_by_request = OpenStax::Biglearn::Api.fetch_assignment_pes(
        ex_requests,
        inline_retry_proc: ->(response) { response[:assignment_status] != 'assignment_ready' }
      )
      spes_by_request = OpenStax::Biglearn::Api.fetch_assignment_spes(
        ex_requests,
        inline_retry_proc: ->(response) { response[:assignment_status] != 'assignment_ready' }
      )
    end

    num_pes_by_task_and_core_page_id = Hash.new { |hash, key| hash[key] = {} }
    pes_by_request.each do |request, pes|
      task = request[:task]

      pes.group_by do |exercise|
        exercise.to_model.content_page_id
      end.each do |page_id, pes|
        num_pes_by_task_and_core_page_id[task][page_id] = pes.size
      end
    end

    num_spes_by_task = {}
    spes_by_request.each { |request, spes| num_spes_by_task[request[:task]] = spes.size }

    tasks.map do |task|
      num_pes_by_core_page_id = num_pes_by_task_and_core_page_id.fetch(task, {})
      num_spes = num_spes_by_task.fetch(task, 0)

      add_task_steps!(
        task: task, num_pes_by_core_page_id: num_pes_by_core_page_id, num_spes: num_spes
      )
    end
  end

  protected

  def add_task_steps!(task:, num_pes_by_core_page_id:, num_spes:)
    reset_used_exercises

    add_core_steps!(task: task, num_pes_by_core_page_id: num_pes_by_core_page_id)

    add_placeholder_steps!(
      task: task,
      group_type: :spaced_practice_group,
      count: num_spes
    )

    task
  end

  def add_core_steps!(task:, num_pes_by_core_page_id:)
    @pages.each do |page|
      # Reading content
      task_fragments(
        task: task,
        fragments: page.fragments,
        page_title: page.tutor_title,
        page: page,
        related_content: page.related_content
      )

      # Personalized exercises after each page
      # Don't add dynamic exercises if all the reading dynamic exercise pools are empty
      # This happens, for example, on intro pages
      num_pes = num_pes_by_core_page_id.fetch(page.id, 0)
      add_placeholder_steps!(
        task: task,
        group_type: :personalized_group,
        count: num_pes,
        page: page
      )
    end

    task
  end

end
