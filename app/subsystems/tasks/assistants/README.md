# Assistants

Assistant Classes must:

  1. Implement the `distribute_tasks(task_plan:, taskees:)`
     singleton method which:
       - Receives as inputs the TaskPlan being assigned and
         the taskees (targets)
       - Creates Task objects and assigns them to the taskees
         based on the task_plan
       - Returns the assigned Tasks

  2. Implement the `schema` singleton method which:
       - Receives no arguments
       - Returns a JSON schema for the task_plan settings hash

Example:

```rb
class AbstractAssistant

  def self.schema
    {}
  end

  def self.distribute_tasks(task_plan:, taskees:)
    raise NotImplementedError
  end

end
```
