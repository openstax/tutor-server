module Catalog
  class CreateOffering

    lev_routine express_output: :offering

    protected

    def exec(attributes)
      offering_model = Catalog::Models::Offering.create(attributes)
      outputs.offering = Catalog::Offering.new(strategy: offering_model.wrap)
      transfer_errors_from(offering_model, {type: :verbatim}, true)
    end

  end
end
