# Assistants

Assistant Classes must:

  1. Implement the `initialize(task_plan:, individualized_tasking_plans:)` method which:
       - Receives as inputs and stores the TaskPlan being assigned
         and the individualized_tasking_plans, which are Tasks::Models::TaskingPlans
         having as targets the individual Entity::Roles being assigned to (the taskees)

  2. Implement the `build_tasks` method which:
       - Builds Task objects for the task_plan and individualized_tasking_plans
         given during initialization
       - Returns an array containing the Tasks::Models::Task to be assigned, in order

  3. Implement the `schema` singleton method which:
       - Receives no arguments
       - Returns a JSON schema for the task_plan settings hash

Example:

```rb
class AbstractAssistant

  attr_reader :task_plan, :individualized_tasking_plans

  def self.schema
    {}
  end

  def initialize(task_plan:, individualized_tasking_plans:)
    @task_plan = task_plan
    @individualized_tasking_plans = individualized_tasking_plans
  end

  def build_tasks
    individualized_tasking_plans.map{ |role| raise NotImplementedError }
  end

end
```
