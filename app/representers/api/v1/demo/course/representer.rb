class Api::V1::Demo::Course::Representer < Roar::Decorator
  include Representable::JSON::Hash
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  # Provide id if the course exists, name otherwise
  property :course,
           decorator: Api::V1::Demo::CourseRepresenter,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  # If the course does not yet exist, then the catalog_offering is required
  property :catalog_offering,
           decorator: Api::V1::Demo::CatalogOfferingRepresenter,
           readable: true,
           writeable: true

  property :is_college,
           type: :boolean,
           readable: true,
           writeable: true

  property :term,
           type: String,
           readable: true,
           writeable: true

  property :year,
           type: Integer,
           readable: true,
           writeable: true

  property :starts_at,
           type: String,
           readable: true,
           writeable: true

  property :ends_at,
           type: String,
           readable: true,
           writeable: true

  collection :teachers,
             extend: Api::V1::Demo::UserRepresenter,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  collection :periods,
             extend: Api::V1::Demo::Course::Period::Representer,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
