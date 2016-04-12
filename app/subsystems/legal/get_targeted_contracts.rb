class Legal::GetTargetedContracts
  lev_routine express_output: :contracts

  protected

  def exec(ids: :all, applicable_to: nil)
    models =
      if applicable_to.present?
        targeted_contract_models_for_gid(Legal::Utils.gid(applicable_to))
      elsif :all == ids
        Legal::Models::TargetedContract.all
      else
        ids = [ids].flatten.compact
        Legal::Models::TargetedContract.find(ids)
      end

    outputs.contracts = models.map(&:as_poro)
  end

  def targeted_contract_models_for_gid(gid)
    parent_gids = Legal::Models::TargetedContractRelationship.all_parent_gids_of(gid)
    potential_target_gids = [gid] + parent_gids

    Legal::Models::TargetedContract.where(target_gid: potential_target_gids).all
  end
end



