module Catalog
  class CreateOffering
    lev_routine express_output: :offering

    protected

    def exec(attributes)
      outputs.offering = Catalog::Models::Offering.create(attributes)
      transfer_errors_from(outputs.offering, { type: :verbatim }, true)
    end
  end
end
