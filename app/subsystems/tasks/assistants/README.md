# Assistants

Assistant Classes must:

  1. Implement the `initialize(task_plan:, roles:)` method which:
       - Receives as inputs and stores the TaskPlan being assigned
         and the Entity::Roles being assigned to (taskees)

  2. Implement the `build_tasks` method which:
       - Builds Task objects for the task_plan and roles given during initialization
       - Returns an array containing the Tasks::Models::Task to be assigned to the roles (in order)

  3. Implement the `schema` singleton method which:
       - Receives no arguments
       - Returns a JSON schema for the task_plan settings hash

Example:

```rb
class AbstractAssistant

  attr_reader :task_plan, :roles

  def self.schema
    {}
  end

  def initialize(task_plan:, roles:)
    @task_plan = task_plan
    @roles = roles
  end

  def build_tasks
    roles.map{ |role| raise NotImplementedError }
  end

end
```
