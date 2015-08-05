class Legal::ForgetAbout
  lev_routine

  protected

  def exec(item:)
    gid = Legal::Utils.gid(item)

    Legal::Models::TargetedContractRelationship.destroy_all(child_gid: gid)
    Legal::Models::TargetedContractRelationship.destroy_all(parent_gid: gid)
    Legal::Models::TargetedContract.destroy_all(target_gid: gid)
  end
end
