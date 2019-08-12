class Api::V1::Demo::Import::Book::ReadingProcessingInstructionRepresenter < Api::V1::Demo::BaseRepresenter
  property :css,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :fragments,
             type: String,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  collection :labels,
             type: String,
             readable: true,
             writeable: true

  collection :only,
             type: String,
             readable: true,
             writeable: true

  collection :except,
             type: String,
             readable: true,
             writeable: true
end
