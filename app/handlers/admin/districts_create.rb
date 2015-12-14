class Admin::DistrictsCreate
  lev_handler uses: { name: SchoolDistrict::CreateDistrict, as: :create_district }

  paramify :district do
    attribute :name, type: String
    validates :name, presence: true
  end

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:create_district, name: district_params.name)
  end
end
