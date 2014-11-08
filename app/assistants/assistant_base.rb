require 'json-schema'

class AssistantBase
  attr_reader :config, :errors

  class_attribute :schema
  class_attribute :data
  class_attribute :task_plan_types

  self.schema = {}
  self.data = {}
  self.task_plan_types = {}

  def self.configure(schema:)
    self.schema = schema
  end

  def self.supports_task_plan(type:, schema:)
    self.task_plan_types ||= {}
    self.task_plan_types[type] = schema
  end

  def self.task_plan_configuration(type)
    self.task_plan_types[type].tap do |config|
      raise IllegalArgument, "invalid type: #{type}" if config.nil?
    end
  end

  def initialize(settings:, data:)
    @errors = JSON::Validator.fully_validate(self.schema, 
                                             settings,
                                             insert_defaults: true)
    return unless @errors.empty?
    @config = config
  end

  def get_task_plan_types
    self.task_plan_types.keys
  end

  def new_task_plan(type)
    task_plan = TaskPlan.new(
      type: type.to_s,
      configuration: self.class.task_plan_configuration(type)
    )
  end

  def create_and_distribute_tasks(task_plan)
    # How can we make Assistants more routine-ish
    taskees = GetTaskeesFromTaskPlan.call(task_plan).outputs[:taskees]

    # Concrete Assistants need to override this to create Tasks from the provided 
    # TaskPlan and assign to the taskees
    task_taskees(task_plan, taskees)
  end
end
