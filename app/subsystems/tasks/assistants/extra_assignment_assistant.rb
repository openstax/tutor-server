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

  def initialize(task_plan:, roles:)
    super

    outputs = collect_snap_labs
    @pages = outputs[:pages]
    @page_id_to_snap_lab_id = outputs[:page_id_to_snap_lab_id]
  end

  def build_tasks
    roles.map{ build_extra_task(pages: @pages, page_id_to_snap_lab_id: @page_id_to_snap_lab_id) }
  end

  protected

  def collect_snap_labs
    # Snap lab ids from the FE contain the page id and the snap lab note id
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
    task = build_task(type: :extra, default_title: 'Extra Assignment')

    reset_used_exercises

    pages.each do |page|
      page.snap_labs.each do |snap_lab|
        # Snap lab ids from the BE contains only the snap lab note id
        # For example, on page id 100, a snap lab note with id "fs-id1164355841632"
        # the snap lab id is "fs-id1164355841632"
        snap_lab_id = snap_lab[:id]
        if page_id_to_snap_lab_id[page.id.to_s].include?(snap_lab_id)
          task_fragments(task: task, fragments: snap_lab[:fragments],
                         page_title: snap_lab[:title], page: page)
        end
      end
    end

    task
  end

end
