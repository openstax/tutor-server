# Assistants

Assistant Classes must:

  1. Implement the `initialize(task_plan:, taskees:)` method which:
       - Receives as inputs and stores the TaskPlan being assigned and the taskees (targets)

  2. Implement the `build_tasks` method which:
       - Builds Task objects for the TaskPlan given during initialization
       - Returns an array containing the Entity::Tasks to be assigned to the taskees (in order)

  3. Implement the `schema` singleton method which:
       - Receives no arguments
       - Returns a JSON schema for the task_plan settings hash

Example:

```rb
class AbstractAssistant

  def self.schema
    {}
  end

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
  end

  def build_tasks
    @taskees.map do |taskee|
      raise NotImplementedError
    end
  end

end
```
