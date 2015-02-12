# Assistants

Assistant Classes must:

  1. Implement the `distribute_tasks(task_plan:, taskees:, settings:, data:)`
     singleton method which:
       - Receives as inputs the TaskPlan being assigned, the taskees (targets),
         the settings from the Course/Teacher/Study and the previously
         stored assistant data
       - Creates Task objects and assigns them to the taskees based on
         the settings and the data
       - Returns the new data hash to be stored in the assistant's storage

  2. Implement the `schema` singleton method which:
       - Receives no arguments
       - Returns a JSON schema for the settings hash

Example:

```rb
module Assistants
  class Abstract

    def self.schema
      {}
    end

    def self.distribute_tasks(task_plan:, taskees:, settings:, data:)
      raise NotImplementedError
    end

  end
end
```
