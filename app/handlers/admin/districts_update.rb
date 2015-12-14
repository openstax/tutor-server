class Admin::DistrictsUpdate
  lev_handler uses: { name: SchoolDistrict::UpdateDistrict, as: :update_district }

  paramify :district do
    attribute :name, type: String
    validates :name, presence: true
  end

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:update_district, id: params[:id], attributes: district_params.as_hash(:name))
  end
end
