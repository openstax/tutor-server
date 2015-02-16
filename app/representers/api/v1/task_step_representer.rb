module Api::V1
  class TaskStepRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    # helper to convert "TaskedFooBar" to "foo_bar", e.g. "TaskedReading" -> "reading"
    def self.external_tasked_type_string(klass_name)
      klass_name.gsub("Tasked","").underscore.downcase
    end

    property :id, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: true
             }

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda { |*| TaskStepRepresenter.external_tasked_type_string(tasked_type) },
             schema_info: {
               required: true,
               description: "The type of this TaskStep, one of: #{
                            TaskedRepresenterMapper.models.collect{ |klass| 
                              "'" + external_tasked_type_string(klass.name) + "'"
                            }.join(',')}"
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this TaskStep"
             }

    property :is_completed,
             writeable: false,
             readable: true,
             getter: lambda {|*| completed?},
             schema_info: {
               required: true,
               description: "Whether or not this step is complete"
             }

  end
end
