module Catalog
  class GetOffering
    lev_routine express_output: :offering

    protected

    def exec(query)
      offering = Catalog::Models::Offering.find_by(query)
      return if offering.nil?

      outputs.offering = Catalog::Offering.new(
        strategy: Catalog::Strategies::Direct::Offering.new(offering)
      )
    end

  end
end
