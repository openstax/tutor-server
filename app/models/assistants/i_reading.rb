module Assistants
  class IReading

    def self.schema
      '{
        "type": "object",
        "required": [
          "page_id"
        ],
        "properties": {
          "page_id": {
            "type": "integer"
          }
        },
        "additionalProperties": false
      }'
    end

    def self.distribute_tasks(task_plan:, taskees:, settings:, data:)
      page = Page.find(settings[:page_id])
      doc = Nokogiri::HTML(page.content || '')
    end

  end
end
