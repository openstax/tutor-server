module Api::V1::Tasks
  class TaskStepRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    INCLUDE_CONTENT = ->(user_options:, **) { user_options.try!(:[], :include_content) }

    # These properties will be included in specific Tasked steps; therefore
    # their getters will be called from that context and so must call up to
    # the "task_step" to access data in the TaskStep "base" class.
    #
    # Using included properties instead of decorator inheritance makes it easier
    # to render and parse json -- there is no confusion about which level to use
    # it is always just the Tasked level and properties that access "base" class
    # values always reach up to it.

    property :id,
             writeable: false,
             getter: ->(*) { task_step.id },
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { self.class.name.demodulize.remove("Tasked").underscore.downcase },
             schema_info: {
               required: true,
               description: "The type of this TaskStep (exercise, reading, video, placeholder, etc.)"
             }

    property :group_name,
             as: :group,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { task_step.group_name },
             schema_info: {
                required: true,
                description: "Which group this TaskStep belongs to (default,core,spaced practice,personalized)"
             }

    property :is_completed,
             writeable: false,
             readable: true,
             getter: ->(*) { task_step.completed? },
             schema_info: {
               required: true,
               type: 'boolean',
               description: "Whether or not this step is complete"
             }

    property :spy,
             type: Object,
             readable: true,
             writeable: false,
             getter: ->(*) { task_step.spy },
             if: INCLUDE_CONTENT
  end
end
