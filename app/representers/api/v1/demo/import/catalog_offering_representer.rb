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
end
