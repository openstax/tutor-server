class Api::V1::Demo::Course::Representer < Api::V1::Demo::BaseRepresenter
  # If the course does not yet exist, then the catalog_offering is required
  property :catalog_offering,
           extend: Api::V1::Demo::CatalogOfferingRepresenter,
           class: Demo::Mash,
           readable: true,
           writeable: true

  property :course,
           extend: Api::V1::Demo::Course::CourseRepresenter,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
