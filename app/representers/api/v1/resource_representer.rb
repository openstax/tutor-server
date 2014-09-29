module Api::V1
  class ResourceRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: true
             }

    property :url,
             type: String,
             writeable: false,
             schema_info: {
               required: false,
               description: "The URL for retrieving the version of the Resource used by Tutor"
             }             

    property :url_is_permalink,
             writeable: false,
             schema_info: {
               required: true,
               description: "Tells us if the content is known to never change (easily cached)"
             }             

    property :content, 
             type: Integer,
             writeable: false,
             schema_info: {
               required: false,
               description: "The content for this Resource, possibly retrieved from the Resource's URL"
             }

  end
end
