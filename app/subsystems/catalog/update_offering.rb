module Catalog
  class UpdateOffering
    lev_routine

    protected

    def exec(id, attributes)
      offering = Models::Offering.find(id)
      offering.update_attributes(attributes)
      transfer_errors_from(offering, {type: :verbatim}, true)
    end

  end
end
