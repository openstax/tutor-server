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
             writeable: false,
             getter: ->(*) { "#{name} #{description}".strip }

    property :chapter_section,
             type: Array,
             readable: true,
             writeable: false,
             if: ->(*) { !chapter_section.blank? },
             schema_info: {
               required: false,
               description: 'The chapter and section in the book, e.g. [5, 2]'
             }

    property :data,
             type: String,
             readable: true,
             writeable: false

  end
end
