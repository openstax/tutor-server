# Assistants

Assistant Classes must:

  1. Implement the `build_tasks(task_plan:, taskees:)`
     singleton method which:
       - Receives as inputs the TaskPlan being assigned and the taskees (targets)
       - Builds Task objects
       - Returns an array containing the Entity::Tasks to be assigned to the taskees (in order)

  2. Implement the `schema` singleton method which:
       - Receives no arguments
       - Returns a JSON schema for the task_plan settings hash

Example:

```rb
class AbstractAssistant

  def self.schema
    {}
  end

  def self.build_tasks(task_plan:, taskees:)
    taskees.collect do |taskee|
      raise NotImplementedError
    end
  end

end
```
