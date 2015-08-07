class Legal::MakeChildNotGetParentContracts
  lev_routine

  protected

  def exec(child:, parent:)
    Legal::Models::TargetedContractRelationship.destroy_all(
      child_gid: Legal::Utils.gid(child),
      parent_gid: Legal::Utils.gid(parent)
    )
  end
end
