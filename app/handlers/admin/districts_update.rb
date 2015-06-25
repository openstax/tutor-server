class Admin::DistrictsUpdate
  lev_handler

  paramify :district do
    attribute :name, type: String
    validates :name, presence: true
  end

  uses_routine UpdateDistrict

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:update_district, id: params[:id],
                          attributes: district_params.as_hash(:name),
                          caller: caller)
  end
end
