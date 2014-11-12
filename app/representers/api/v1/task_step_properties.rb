module Api::V1
  module TaskStepProperties

    include Roar::Representer::JSON

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
             getter: lambda { |*| details_type.downcase },
             schema_info: {
               required: true,
               description: "The type of this TaskStep, one of: #{Api::V1::TaskStepRepresenterMapper.models.collect{|klass| "'" + klass.name.downcase + "'"}.join(',')}"
             }

    property :title,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: true,
               description: "The title of this step"
             }

  end
end
