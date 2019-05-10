class Legal::ForgetAbout
  lev_routine

  protected

  def exec(item:)
    gid = Legal::Utils.gid(item)

    Legal::Models::TargetedContract.where(target_gid: gid).destroy_all
  end
end
