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

    property :content,
             readable: true,
             writeable: false,
             getter: ->(*) { ::JSON.parse(content) },
             schema_info: { required: true }

    collection :tags,
               readable: true,
               writeable: false,
               getter: -> (*) { tags.select { |tag| tag.visible? } },
               decorator: TagRepresenter,
               schema_info: { required: true,
                              description: 'Tags for this exercise' }

  end
end
