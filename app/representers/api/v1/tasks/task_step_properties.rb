module Api::V1::Tasks
  module TaskStepProperties

    include Roar::JSON
    include Representable::Coercion

    # These properties will be included in specific Tasked steps; therefore
    # their getters will be called from that context and so must call up to
    # the "task_step" to access data in the TaskStep "base" class.
    #
    # Using included properties instead of decorator inheritance makes it easier
    # to render and parse json -- there is no confusion about which level to use
    # it is always just the Tasked level and properties that access "base" class
    # values always reach up to it.

    property :id,
             type: String,
             writeable: false,
             getter: -> (*) { task_step.id },
             schema_info: {
               required: true
             }

    property :task_id,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda {|*| task_step.tasks_task_id },
             schema_info: {
                 required: true,
                 description: "The id of the Task"
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda { |*| self.class.name.demodulize.remove("Tasked")
                                                 .underscore.downcase },
             schema_info: {
               required: true,
               description: "The type of this TaskStep"
             }

    property :is_completed,
             writeable: false,
             readable: true,
             getter: lambda {|*| task_step.completed?},
             schema_info: {
               required: true,
               type: 'boolean',
               description: "Whether or not this step is complete"
             }

    collection :related_content,
               writeable: false,
               readable: true,
               # decorator: TaskStepRepresenter,
               getter: lambda {|*| task_step.related_content },
               schema_info: {
                 required: true,
                 description: "Misc information related to this exercise"
               }

  end
end
