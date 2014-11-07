require 'json-schema'

class AssistantBase
  attr_reader :config, :errors

  def self.configure(schema:)
    @@schema = schema
  end

  def self.supports_task_plan(type:, schema:)
    @@task_plan_types ||= {}
    @@task_plan_types[type] = schema
  end

  def initialize(settings:, data:)
    @errors = JSON::Validator.fully_validate(@@schema, 
                                             settings,
                                             insert_defaults: true)
    return unless @errors.empty?
    @config = config
  end

  def get_task_plan_types
    @@task_plan_types.keys
  end

  def new_task_plan(type)
    task_plan = TaskPlan.new

    task_plan.configuration = @@task_plan_types[type]
    raise IllegalArgument, "invalid type: #{type}" if task_plan.configuration.nil?
    task_plan
  end

  def create_and_distribute_tasks(task_plan)
    # How can we make Assistants more routine-ish
    taskees = GetTaskeesFromTaskPlans.call(task_plan.tasking_plans).outputs[:taskees]

    # Concrete Assistants need to override this to create Tasks from the provided 
    # TaskPlan and assign to the taskees
    task_taskees(task_plan, taskees)
  end
end
