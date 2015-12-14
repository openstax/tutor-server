module Catalog
  class CreateOffering
    lev_routine outputs: { offering: :_self }

    protected

    def exec(attributes)
      offering = Models::Offering.create(attributes)
      transfer_errors_from(offering, {type: :verbatim}, true)
      strategy = Strategies::Direct::Offering.new(offering)
      set(offering: Offering.new(strategy: strategy))
    end

  end
end
