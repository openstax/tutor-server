class Catalog::ListOfferings

  lev_routine express_output: :offerings

  protected

  def exec
    outputs.offerings = Catalog::Models::Offering.preload_deletable.map do |offering|
      Catalog::Offering.new(strategy: offering.wrap)
    end
  end

end
