module Api::V1::Tasks
  class TaskStepRepresenter < Roar::Decorator

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
             getter: ->(*) { task_step.id },
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
               description: "The type of this TaskStep (exercise, reading, video, placeholder, etc.)"
             }

    property :group_name,
             as: :group,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda {|*| task_step.group_name },
             schema_info: {
                required: true,
                description: "Which group this TaskStep belongs to (default,core,spaced practice,personalized)"
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

    property :last_completed_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(last_completed_at) },
             schema_info: { description: "The most recent completion date by the taskee" }

    property :first_completed_at,
             type: String,
             writeable: false,
             readable: true,
             getter: ->(*) { DateTimeUtilities.to_api_s(first_completed_at) },
             schema_info: { description: "The first completion date by the taskee" }

    property :can_be_recovered?,
             as: :has_recovery,
             writeable: false,
             readable: true,
             schema_info: {
               type: 'boolean',
               description: "Whether or not a recovery exercise is available"
             }

    collection :related_content,
               writeable: false,
               readable: true,
               getter: ->(*) {
                 task_step.related_content.map{ |rc| Hashie::Mash.new(rc) }
               },
               extend: ::Api::V1::RelatedContentRepresenter,
               schema_info: {
                 required: true,
                 description: "Misc content related to this step"
               }

    collection :labels,
               writeable: false,
               readable: true,
               getter: ->(*) { task_step.labels },
               schema_info: {
                 required: true,
                 description: "Misc properties related to this step"
               }

  end
end
