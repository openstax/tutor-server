class Content::ListEcosystems
  lev_routine outputs: { ecosystems: :_self }

  protected

  def exec
    set(ecosystems: ::Content::Ecosystem.all)
  end
end
