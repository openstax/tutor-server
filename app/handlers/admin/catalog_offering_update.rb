class Admin::CatalogOfferingUpdate
  lev_handler

  uses_routine Catalog::UpdateOffering, as: :update_offering

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:update_offering, params[:id], params[:offering])
  end
end
