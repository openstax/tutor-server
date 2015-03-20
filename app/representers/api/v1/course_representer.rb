module Api::V1
  class CourseRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    property :id, readable: true, schema_info: { required: true }

    property :name, readable: true, schema_info: { required: true }

    collection :roles, extend: Api::V1::RoleRepresenter,
      readable: true, schema_info: { required: false }

  end
end
