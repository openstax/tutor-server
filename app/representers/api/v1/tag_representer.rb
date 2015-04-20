module Api::V1
  class TagRepresenter < Roar::Decorator

    include Roar::JSON

    property :value,
             as: :id,
             type: String,
             readable: true,
             writeable: false

    property :tag_type,
             as: :type,
             type: String,
             readable: true,
             writeable: false

    property :name,
             type: String,
             readable: true,
             writeable: false

    property :description,
             type: String,
             readable: true,
             writeable: false

    property :chapter_section,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: false,
               description: 'The chapter and section in the book, e.g. "5.2"'
             }

  end
end
