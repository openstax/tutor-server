require 'json-schema'

module AssistantModules
  class Base
    attr_reader :config, :errors

    def self.initialize(config)
      @errors = JSON::Validator.fully_validate(schema, config,
                                               :insert_defaults => true)
      return unless @errors.empty?
      @config = config
    end

    # Override this to provide a schema object
    def self.schema
      {}
    end

    # Override this to create and assign Tasks for each target
    def create_tasks_for(target)
      raise NotYetImplemented
    end
  end
end
