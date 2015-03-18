module Api::V1
  class RoleRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :type,
             type: String,
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
               required: true
             }
  end
end
