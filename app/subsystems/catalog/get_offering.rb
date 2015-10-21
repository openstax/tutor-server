module Catalog
  class GetOffering
    lev_routine express_output: :offering

    protected

    def exec(query)
      outputs.offering = Models::Offering.where(query).first
    end

  end
end
