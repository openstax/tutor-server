class Legal::MakeChildGetParentContracts
  lev_routine

  protected

  def exec(child:, parent:)
    Legal::Models::TargetedContractRelationship.find_or_create_by(
      child_gid: Legal::Utils.gid(child),
      parent_gid: Legal::Utils.gid(parent)
    )
  end
end
