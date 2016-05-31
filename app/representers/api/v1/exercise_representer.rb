module Api::V1
  class ExerciseRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: true,
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

    property :preview,
             readable: true,
             writeable: false

    property :context,
             readable: true,
             writeable: false

    property :content,
             readable: true,
             writeable: false,
             getter: ->(*) { respond_to?(:content_hash) ? content_hash : content },
             schema_info: { required: true }

    collection :tags,
               readable: true,
               writeable: false,
               decorator: ->(obj, *) { (obj.is_a?(Content::Models::Tag) || \
                                        obj.is_a?(Content::Tag)) ? TagRepresenter : nil },
               getter: ->(*) { (tags + tags.flat_map(&:teks_tags)).compact.uniq },
               schema_info: { required: true, description: 'Tags for this exercise' }

    collection :pool_types,
               readable: true,
               writeable: false

    property :is_excluded,
             readable: true,
             writeable: true,
             schema_info: { type: 'boolean' }

    property :has_interactive,
             readable: true,
             writeable: true,
             schema_info: { type: 'boolean' }

    property :has_video,
             readable: true,
             writeable: true,
             schema_info: { type: 'boolean' }

  end
end
