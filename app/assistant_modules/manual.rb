require 'json-schema'

module AssistantModules
  class Representer
    def self.schema
      RepresentableSchemaPrinter.json(Api::V1::TaskRepresenter)
    end

    def create_tasks_for(target)
      taskees = TargetToTaskees.call(target).outputs[:taskees]
      Task.transaction do
        taskees.each do |taskee|
          task = Task.new
          Api::V1::TaskRepresenter.new(task).from_json(@configuration.to_json)
          task.save!

          Tasking.create!(task: task, taskee: taskee)
        end
      end
    end
  end
end
