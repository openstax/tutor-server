class Catalog::ListOfferings

  lev_routine outputs: { offerings: :_self }

  protected

  def exec
    set(offerings: Catalog::Models::Offering.all.map do | offering |
      Catalog::Offering.new(strategy: Catalog::Strategies::Direct::Offering.new(offering) )
    end)
  end

end
