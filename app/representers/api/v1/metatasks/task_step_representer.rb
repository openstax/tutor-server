module Api::V1::Metatasks
  class TaskStepRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    FEEDBACK          = ->(user_options:, **) { !user_options.try! :[], :no_feedback }
    NOT_FEEDBACK_ONLY = ->(user_options:, **) { !user_options.try! :[], :feedback_only }

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
             getter: ->(*) { task_step.id },
             schema_info: {
               required: true
             },
             if: NOT_FEEDBACK_ONLY

    property :task_id,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { task_step.tasks_task_id },
             schema_info: {
                 required: true,
                 description: "The id of the Task"
             },
             if: NOT_FEEDBACK_ONLY

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { self.class.name.demodulize.remove("Tasked").underscore.downcase },
             schema_info: {
               required: true,
               description: "The type of this TaskStep (exercise, reading, video, placeholder, etc.)"
             },
             if: NOT_FEEDBACK_ONLY

    property :is_completed,
             writeable: false,
             readable: true,
             getter: ->(*) { task_step.completed? },
             schema_info: {
               required: true,
               type: 'boolean',
               description: "Whether or not this step is complete"
             },
             if: NOT_FEEDBACK_ONLY
  end
end
