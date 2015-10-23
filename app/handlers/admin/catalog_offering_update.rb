class Admin::CatalogOfferingUpdate
  lev_handler

  paramify :offering do
    attribute :identifier, type: String
    attribute :description, type: String
    attribute :content_ecosystem_id
    attribute :is_tutor, type: boolean
    attribute :is_concept_coach, type: boolean
    attribute :webview_url, type: String
    attribute :pdf_url, type: String

    validates :identifier, :description, :webview_url, :pdf_url, presence: true
  end

  uses_routine Catalog::UpdateOffering, as: :update_offering

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    attributes = offering_params.as_json
    run(:update_offering, params[:id], attributes)
  end
end
