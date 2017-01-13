class Admin::CatalogOfferingUpdate
  lev_handler

  uses_routine Catalog::UpdateOffering, as: :update_offering,
                                        translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:update_offering, params[:id], offering_params, params[:update_courses])
  end

  def offering_params
    params.require(:offering).permit!
  end
end
