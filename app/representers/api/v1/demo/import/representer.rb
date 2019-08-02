class Api::V1::Demo::Import::Representer < Api::V1::Demo::BaseRepresenter
  property :book,
           extend: Api::V1::Demo::Import::Book::Representer,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :catalog_offering,
           extend: Api::V1::Demo::Import::CatalogOfferingRepresenter,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
