module Api::V1
  class InteractiveRepresenter < Roar::Decorator
    include Api::V1::TaskStepProperties

    property :url,
             type: String,
             getter: lambda {|*| details.url},
             writeable: false,
             readable: true,
             as: :content_url,
             schema_info: {
               required: false,
               description: "The URL where the interactive can be found"
             }

    property :content,
             type: String,
             getter: lambda {|*| details.content},
             writeable: false,
             readable: true,
             as: :content_html,
             schema_info: {
               required: false,
               description: "The interactive content as HTML"
             }
                          
  end
end
