module Api::V1
  class ReadingRepresenter < TaskRepresenter
    include Roar::Representer::JSON

    property :type,
             type: String,
             writeable: false,
             readable: true,
             getter: lambda {|*| "Reading"},
             schema_info: {
               required: true,
               description: "The type of this Task, one of ['Reading', 'Homework']"
             }

    property :id, 
             type: Integer,
             writeable: false,
             readable: true,
             schema_info: {
               required: true
             }

    property :url,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The URL where the reading material can be found"
             }

    property :content,
             type: String,
             writeable: false,
             readable: true,
             schema_info: {
               required: false,
               description: "The reading content as HTML"
             }
                          
  end
end
