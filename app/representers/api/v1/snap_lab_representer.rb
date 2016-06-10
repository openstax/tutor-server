module Api::V1
  class SnapLabRepresenter < Roar::Decorator
    include Roar::JSON

    property :id,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { "#{page_id}:#{id}" },
             schema_info: {
               required: true,
               description: 'Id of the note with snap lab'
             }

    property :title,
             type: String,
             readable: true,
             writeable: false,
             schema_info: {
               required: true,
               description: 'Title of the note with snap lab'
             }
  end
end
