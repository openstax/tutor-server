class Api::V1::OfferingSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

  collection :items, inherit: true, extend: Api::V1::OfferingRepresenter

end
