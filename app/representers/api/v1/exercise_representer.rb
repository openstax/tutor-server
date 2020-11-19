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
             type: String,
             readable: true,
             writeable: false

    property :context,
             type: String,
             readable: true,
             writeable: false

    property :content,
             type: Object,
             readable: true,
             writeable: false,
             getter: ->(user_options:, **) {
               user_options&.[](:for_student) ? parser.content_hash_for_students :
                 respond_to?(:content_hash) ? content_hash : content
             },
             schema_info: { required: true }

    property :files_path,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(user_options:, **) {
      ''
#               Rails.application.routes.url_helpers.rails_blob_path(self, only_path: true)
             }

    collection :tags,
               readable: true,
               writeable: false,
               # We really only need :prepare here, but for some reason representable
               # will not run :prepare without :decorator (or :extend) being present
               extend: TagRepresenter,
               prepare: ->(input:, **) do
                 input.is_a?(Content::Models::Tag) ? TagRepresenter.new(input) : input
               end,
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
             writeable: false,
             schema_info: { type: 'boolean' }

    property :has_video,
             readable: true,
             writeable: false,
             schema_info: { type: 'boolean' }

    property :page_uuid,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { respond_to?(:page_uuid) ? page_uuid : page.try(:uuid) },
             schema_info: { required: true }

    property :author,
             extend: Api::V1::ExerciseAuthorRepresenter
  end
end
