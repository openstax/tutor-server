class Api::V1::Demo::Import::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :archive_url_base,
           type: String,
           readable: true,
           writeable: true

  property :webview_url_base,
           type: String,
           readable: true,
           writeable: true

  property :pdf_url_base,
           type: String,
           readable: true,
           writeable: true

  property :title,
           type: String,
           readable: true,
           writeable: true

  property :description,
           type: String,
           readable: true,
           writeable: true

  property :cnx_book_id,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :cnx_book_version,
           type: String,
           readable: true,
           writeable: true

  property :appearance_code,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :default_course_name,
           type: String,
           readable: true,
           writeable: true

  property :salesforce_book_name,
           type: String,
           readable: true,
           writeable: true

  collection :reading_processing_instructions,
             extend: Api::V1::Demo::Import::ReadingProcessingInstructionRepresenter,
             class: Demo::Mash,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
