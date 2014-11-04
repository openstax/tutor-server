module Api::V1
  class ReadingRepresenter < Roar::Decorator

    include Api::V1::TaskStepProperties

    property :url,
             type: String,
             writeable: false,
             readable: true,
             as: :content_url,
             schema_info: {
               required: false,
               description: "The URL where the reading material can be found"
             }

    property :content,
             type: String,
             writeable: false,
             readable: true,
             as: :content_html,
             schema_info: {
               required: false,
               description: "The reading content as HTML"
             }

  end
end
