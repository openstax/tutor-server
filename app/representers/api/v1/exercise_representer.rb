module Api::V1
  class ExerciseRepresenter < Roar::Decorator

    include Roar::JSON

    property :id, readable: true, schema_info: { required: true }

    property :url, readable: true, schema_info: { required: true }

    property :title, readable: true, schema_info: { required: true }

    property :content, readable: true, schema_info: { required: true }

  end
end
