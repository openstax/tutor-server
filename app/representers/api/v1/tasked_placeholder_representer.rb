module Api::V1
  class TaskedPlaceholderRepresenter < Roar::Decorator

    include Roar::JSON

    property :id,
             type: Integer,
             writeable: false,
             getter: -> (*) { task_step.id },
             schema_info: {
               required: true
             }

    property :task_id,
             type: Integer,
             writeable: false,
             readable: true,
             getter: lambda {|*| task_step.tasks_task_id },
             schema_info: {
                 required: true,
                 description: "The id of the Task"
             }

    property :is_completed,
             type: 'boolean',
             writeable: false,
             readable: true,
             getter: lambda {|*| task_step.completed?},
             schema_info: {
               required: true,
               description: "Whether or not this step is complete"
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda { |*| 'exercise' },
             schema_info: {
               required: true,
               description: "The type of this TaskStep, one of: #{
                            TaskedRepresenterMapper.models.collect{ |klass|
                              "'" + klass.name.demodulize.remove("Tasked")
                                         .underscore.downcase + "'"
                            }.reject{|m| m == 'placeholder'}.join(',')}"
             }

    property :url,
             type: String,
             writeable: false,
             readable: true,
             as: :content_url,
             schema_info: {
               required: false,
               description: "The source URL for this Exercise"
             }

    property :content,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The Exercise's content without correctness and feedback info"
             }

  end
end
