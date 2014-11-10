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


    # NOT NEEDED WHEN IN COLLECTION
    # property :task_id, 
    #          type: Integer,
    #          writeable: false,
    #          readable: true,
    #          getter: lambda { |*| task_id },
    #          schema_info: {
    #            required: true,
    #            description: "The ID of the Task this step belongs to"
    #          }

    # IMPLIED WHEN IN AN ARRAY, NOT NEEDED WHEN ON ITS OWN
    # property :number, 
    #          type: Integer,
    #          writeable: true,
    #          readable: true,
    #          getter: lambda { |*| number },
    #          schema_info: {
    #            required: true,
    #            description: "The step number for this TaskStep"
    #          }

  end
end
