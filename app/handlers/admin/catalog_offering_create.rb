class Admin::CatalogOfferingCreate
  lev_handler

  uses_routine Catalog::CreateOffering, as: :create_offering

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:create_offering, params["offering"].permit!)
  end
end
