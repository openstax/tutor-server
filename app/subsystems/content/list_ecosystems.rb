class Content::ListEcosystems
  lev_routine express_output: :ecosystems

  protected

  def exec
    outputs[:ecosystems] = ::Content::Ecosystem.all
  end
end
