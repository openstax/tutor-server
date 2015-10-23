module Catalog
  class CreateOffering
    lev_routine express_output: :offering

    protected

    def exec(attributes)
      offering = Models::Offering.create!(attributes)
      strategy = Strategies::Direct::Offering.new(offering)
      outputs.offering = Offering.new(strategy: strategy)
    end

  end
end
