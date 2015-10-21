module Catalog
  class GetOffering
    lev_routine express_output: :offering

    protected

    def exec(query)
      offering = Models::Offering.where(query).first!
      outputs.offering = Catalog::Offering.new(strategy: Catalog::Strategies::Direct::Offering.new(offering) )
    end

  end
end
