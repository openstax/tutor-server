class Catalog::ListOfferings

  lev_routine express_output: :offerings

  protected

  def exec
    outputs.offerings = Catalog::Models::Offering.all

  end
end
