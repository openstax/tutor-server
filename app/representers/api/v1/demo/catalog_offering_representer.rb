class Api::V1::Demo::CatalogOfferingRepresenter < Api::V1::Demo::BaseRepresenter
  # One of either id or title is required
  property :id,
           type: String,
           readable: true,
           writeable: true

  property :title,
           type: String,
           readable: true,
           writeable: true
end
