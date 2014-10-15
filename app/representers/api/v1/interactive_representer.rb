module Api::V1
  class InteractiveRepresenter < Roar::Decorator
    include Api::V1::TaskProperties

    property :url,
             type: String,
             writeable: false,
             readable: true,
             as: :content_url,
             schema_info: {
               required: false,
               description: "The URL where the interactive can be found"
             }

    property :content,
             type: String,
             writeable: false,
             readable: true,
             as: :content_html,
             schema_info: {
               required: false,
               description: "The interactive content as HTML"
             }
                          
  end
end
