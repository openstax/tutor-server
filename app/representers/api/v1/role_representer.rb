module Api::V1
  class RoleRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :type,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

  end
end
