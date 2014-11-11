module Api::V1
  class ExerciseRepresenter < Roar::Decorator
    include Api::V1::TaskStepProperties

    property :url,
             type: String,
             getter: lambda {|*| details.url},
             writeable: false,
             readable: true,
             as: :content_url,
             schema_info: {
               required: false,
               description: "The URL where the exercise can be found"
             }

    property :content,
             type: String,
             getter: lambda {|*| ::JSON.parse(details.content)},
             writeable: false,
             readable: true,
             as: :content_json,
             schema_info: {
               required: false,
               description: "The exercise content as JSON"
             }
                          
  end
end
