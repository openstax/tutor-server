class Legal::ForgetAboutContracts
  lev_routine

  protected

  def exec(with_respect_to:)
    gid = Legal::Utils.gid(with_respect_to)

    Legal::Models::TargetedContractRelationship.destroy_all(child_gid: gid)
    Legal::Models::TargetedContractRelationship.destroy_all(parent_gid: gid)
    Legal::Models::TargetedContract.destroy_all(target_gid: gid)
  end
end
