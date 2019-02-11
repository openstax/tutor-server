module Api::V1

  class NoteRepresenter < ::Roar::Decorator

    include Roar::JSON

    property :id,
             type: String,
             writeable: false,
             readable: true,
             schema_info: { required: true }

    property :anchor,
             type: String,
             writeable: true,
             readable: true,
             schema_info: { required: true }

    property :content_page_id,
             as: :page_id,
             type: Integer,
             writeable: true,
             readable: true,
             schema_info: { required: true }

    property :contents,
             type: Object,
             writeable: true,
             readable: true,
             schema_info: { required: true }

    property :created_at,
             type: String,
             readable: true,
             writeable: false

    property :updated_at,
             type: String,
             readable: true,
             writeable: false
  end

  class NotesRepresenter < Roar::Decorator
    include Representable::JSON::Collection
    items extend: NoteRepresenter
  end

end
