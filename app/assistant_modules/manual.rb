module AssistantModules
  class Manual < Base
    def self.schema
      RepresentableSchemaPrinter.json(Api::V1::TaskRepresenter)
    end

    def create_tasks_for(target)
      taskee_groups = TargetToTaskees.call(target).outputs[:taskee_groups]
      Task.transaction do
        taskee_groups.each do |taskee_group|
          task = Task.new
          Api::V1::TaskRepresenter.new(task).from_json(@configuration.to_json)
          task.save!

          taskee_group.each do |taskee|
            Tasking.create!(task: task, taskee: taskee)
          end
        end
      end
    end
  end
end
