# Assistants

Assistant Classes must:

  1. Implement the `create_tasks(task_plan:, taskees:)`
     singleton method which:
       - Receives as inputs the TaskPlan being assigned and the taskees (targets)
       - Builds Task objects and calls yield(task, taskee) to assign them and set the dates
       - Saves the Tasks
       - Returns an array containing the Tasks

  2. Implement the `schema` singleton method which:
       - Receives no arguments
       - Returns a JSON schema for the task_plan settings hash

Example:

```rb
class AbstractAssistant

  def self.schema
    {}
  end

  def self.create_tasks(task_plan:, taskees:)
    raise NotImplementedError
  end

end
```
