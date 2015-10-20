module Catalog
  class CreateOffering
    lev_routine

    protected
    def exec(attributes)
      outputs.offering = Models::Offering.create!(attributes)
    end


  end
end
