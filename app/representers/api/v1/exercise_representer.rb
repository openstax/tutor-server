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
             getter: ->(*) { is_a?(Hashie::Mash) ? content : \
                                                   ::JSON.parse(content).except('attachments') },
             schema_info: { required: true }

    collection :tags,
               readable: true,
               writeable: false,
               decorator: TagRepresenter,
               getter: ->(*) { is_a?(Hashie::Mash) ? tags : \
                                                     (tags + tags.flat_map(&:teks_tags)).uniq },
               schema_info: { required: true, description: 'Tags for this exercise' }

    collection :pool_types,
               readable: true,
               writeable: false,
               if: ->(*) { is_a?(Hashie::Mash) }

    property :is_excluded,
             readable: true,
             writeable: true,
             if: ->(*) { is_a?(Hashie::Mash) },
             schema_info: { type: 'boolean' }

  end
end
