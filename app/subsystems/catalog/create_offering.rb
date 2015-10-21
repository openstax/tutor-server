module Catalog
  class CreateOffering
    lev_routine express_output: :offering

    protected

    def exec(attributes)
      outputs.offering = Models::Offering.create!(attributes)
    end

  end
end
