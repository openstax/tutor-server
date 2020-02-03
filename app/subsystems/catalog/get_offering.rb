module Catalog
  class GetOffering
    lev_routine express_output: :offering

    protected

    def exec(query)
      outputs.offering = Catalog::Models::Offering.find_by(query)
    end
  end
end
