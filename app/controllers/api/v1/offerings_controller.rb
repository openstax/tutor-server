class Api::V1::OfferingsController < Api::V1::ApiController
  resource_description do
    api_versions 'v1'
    short_description 'Represents our current course offerings'
    description <<-EOS
      Catalog offerings determine which books can be used by verified teachers
      to create courses and determine their initial settings
    EOS
  end

  api :GET, '/offerings', 'Returns all catalog offerings'
  description <<-EOS
    Returns all catalog offerings
    #{json_schema(Api::V1::OfferingSearchRepresenter, include: :readable)}
  EOS
  def index
    standard_index(Catalog::Models::Offering.where(is_available: true),
                   Api::V1::OfferingSearchRepresenter)
  end
end
