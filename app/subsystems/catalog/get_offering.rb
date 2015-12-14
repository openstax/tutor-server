module Catalog
  class GetOffering
    lev_routine outputs: { offering: :_self }

    protected

    def exec(query)
      offering = Models::Offering.where(query).first
      if offering
        set(offering: Catalog::Offering.new(
          strategy: Catalog::Strategies::Direct::Offering.new(offering)
        ))
      end
    end

  end
end
