module Catalog
  class CreateOffering
    lev_routine express_output: :offering

    protected

    def exec(attributes)
      offering = Catalog::Models::Offering.create(attributes)
      transfer_errors_from(offering, {type: :verbatim}, true)

      strategy = Strategies::Direct::Offering.new(offering)
      outputs.offering = Catalog::Offering.new(strategy: strategy)
    end

  end
end
