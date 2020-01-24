class Api::V1::Demo::Import::CatalogOfferingRepresenter < Api::V1::Demo::CatalogOfferingRepresenter
  property :description,
           type: String,
           readable: true,
           writeable: true

  property :appearance_code,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :salesforce_book_name,
           type: String,
           readable: true,
           writeable: true

  property :default_course_name,
           type: String,
           readable: true,
           writeable: true

  property :webview_url_base,
           type: String,
           getter: ->(*) { "#{webview_url}/contents/" },
           readable: true,
           writeable: true

  property :pdf_url_base,
           type: String,
           getter: ->(*) { "#{pdf_url}/exports/" },
           readable: true,
           writeable: true
end
