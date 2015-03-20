module Api::V1
  class RoleRepresenter < Roar::Decorator
    include Roar::Representer::JSON

    property :id, readable: true, schema_info: { required: true }

    property :type, readable: true, schema_info: { required: true }
  end
end
