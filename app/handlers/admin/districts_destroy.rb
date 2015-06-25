class Admin::DistrictsDestroy
  lev_handler

  uses_routine DeleteDistrict

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:delete_district, id: params[:id], caller: caller)
  end
end
