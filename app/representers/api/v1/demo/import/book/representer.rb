class Api::V1::Demo::Import::Book::Representer < Api::V1::Demo::BaseRepresenter
  property :archive_url_base,
           type: String,
           getter: ->(*) { "#{archive_url}/contents/" },
           readable: true,
           writeable: true

  property :uuid,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :version,
           type: String,
           readable: true,
           writeable: true

  collection :reading_processing_instructions,
             extend: Api::V1::Demo::Import::Book::ReadingProcessingInstructionRepresenter,
             class: Demo::Mash,
             getter: ->(*) { reading_processing_instructions.map { |inst| Demo::Mash.new inst } },
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
