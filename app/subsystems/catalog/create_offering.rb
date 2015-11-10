module Catalog
  class CreateOffering
    lev_routine express_output: :offering

    protected

    def exec(attributes)
      offering = Models::Offering.create(attributes)
      transfer_errors_from(offering, {type: :verbatim}, true)
      strategy = Strategies::Direct::Offering.new(offering)
      outputs.offering = Offering.new(strategy: strategy)
    end

  end
end
