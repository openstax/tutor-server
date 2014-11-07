module Sprint003
  class Assistant < ::AssistantBase

    configure schema: {}

    supports_task_plan type: :study, schema: {}
    supports_task_plan type: :homework, schema: {}

    def task_taskees(task_plan, taskees)
      raise NotYetImplemented
    end

  end
end