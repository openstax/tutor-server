class Tasks::Assistants::ExtraAssignmentAssistant < Tasks::Assistants::FragmentAssistant

  def self.schema
    '{
      "type": "object",
      "required": [
        "snap_lab_ids"
      ],
      "properties": {
        "snap_lab_ids": {
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

    outputs = collect_snap_labs
    @pages = outputs[:pages]
    @page_id_to_snap_lab_id = outputs[:page_id_to_snap_lab_id]
  end

  def build_tasks
    taskees.map do |taskee|
      build_extra_task(pages: @pages, page_id_to_snap_lab_id: @page_id_to_snap_lab_id)
    end
  end

  protected

  def collect_snap_labs
    # Snap lab ids contains the page id and the snap lab note id
    # For example, on page id 100, a snap lab note with id "fs-id1164355841632"
    # the snap lab id is "100:fs-id1164355841632"
    page_to_snap_lab = Hash.new { |hash, key| hash[key] = [] }
    task_plan.settings['snap_lab_ids'].each do |page_snap_lab_id|
      page_id, snap_lab_id = page_snap_lab_id.split(':', 2)
      page_to_snap_lab[page_id] << snap_lab_id
    end

    page_ids = page_to_snap_lab.keys

    {
      pages: ecosystem.pages_by_ids(page_ids),
      page_id_to_snap_lab_id: page_to_snap_lab
    }
  end

  def build_extra_task(pages:, page_id_to_snap_lab_id:)
    task = build_task

    reset_used_exercises

    pages.each do |page|
      page.snap_labs.each do |snap_lab|
        # Snap lab ids contains the page id and the snap lab note id
        # For example, on page id 100, a snap lab note with id "fs-id1164355841632"
        # the snap lab id is "100:fs-id1164355841632"
        snap_lab_id = snap_lab[:id].split(':').last
        if page_id_to_snap_lab_id[page.id.to_s].include?(snap_lab_id)
          task_fragments(task: task, fragments: snap_lab[:fragments],
                         page_title: snap_lab[:title], page: page)
        end
      end
    end

    task
  end

  def build_task
    title = task_plan.title || 'Extra Assignment'
    description = task_plan.description

    Tasks::BuildTask[
      task_plan: task_plan,
      task_type: :extra,
      title: title,
      description: description
    ]
  end

end
