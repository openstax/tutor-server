module Catalog
  class UpdateOffering
    lev_routine

    protected

    def exec(id, attributes)
      Models::Offering.update(id, attributes)
    end

  end
end
