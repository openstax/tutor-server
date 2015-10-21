module Catalog
  class GetOfferingForEcosystem
    lev_routine express_output: :offering

    protected

    def exec(ecosystem)
      outputs.offering = Models::Offering.where(ecosystem: ecosystem).first
    end

  end
end
