module Api::V1
  class ExerciseRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :url,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :title,
             type: String,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    property :content_hash,
             as: :content_json,
             readable: true,
             writeable: false,
             schema_info: { required: true }

    collection :tags_with_teks,
               as: :tags,
               readable: true,
               writeable: false,
               decorator: TagRepresenter,
               schema_info: { required: true, description: 'Tags for this exercise' }

  end
end
