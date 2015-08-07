class Legal::DestroyTargetedContract
  lev_routine

  protected

  def exec(id:)
    tc = Legal::Models::TargetedContract.find(id)
    tc.destroy
    transfer_errors_from(tc, {type: :verbatim})
  end
end
