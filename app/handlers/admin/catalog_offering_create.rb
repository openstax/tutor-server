class Admin::CatalogOfferingCreate
  lev_handler

  uses_routine Catalog::CreateOffering, as: :create_offering,
                                        translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:create_offering, offering_params)
  end

  def offering_params
    params.require(:offering).permit!
  end
end
