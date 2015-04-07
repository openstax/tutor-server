module Api::V1
  class TaskedPlaceholderRepresenter < Roar::Decorator

    include TaskStepProperties

    ## overridden from TaskStepProperties
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
