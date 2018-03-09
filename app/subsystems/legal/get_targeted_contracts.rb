class Legal::GetTargetedContracts
  lev_routine express_output: :contracts

  protected

  def exec(ids: :all, applicable_to: nil)
    models =
      if applicable_to.present?
        gids = [ applicable_to ].flatten.map { |item| Legal::Utils.gid(item) }
        targeted_contract_models_for_gids(gids)
      elsif :all == ids
        Legal::Models::TargetedContract.all
      else
        ids = [ids].flatten.compact
        Legal::Models::TargetedContract.find(ids)
      end

    outputs.contracts = models.map(&:as_poro)
  end

  def targeted_contract_models_for_gids(gids)
    parent_gids = Legal::Models::TargetedContractRelationship.all_parent_gids_of(gids)
    potential_target_gids = gids + parent_gids

    Legal::Models::TargetedContract.where(target_gid: potential_target_gids).all
  end
end
