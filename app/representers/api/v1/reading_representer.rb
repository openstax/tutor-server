module Api::V1
  class ReadingRepresenter < Roar::Decorator
    include Api::V1::TaskProperties

    property :content_url,
             type: String,
             writeable: false,
             readable: true,
             getter: -> {url},
             schema_info: {
               required: false,
               description: "The URL where the reading material can be found"
             }

    property :content_html,
             type: String,
             writeable: false,
             readable: true,
             getter: -> {content},
             schema_info: {
               required: false,
               description: "The reading content as HTML"
             }
                          
  end
end
