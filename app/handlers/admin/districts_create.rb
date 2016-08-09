class Admin::DistrictsCreate
  lev_handler

  paramify :district do
    attribute :name, type: String
    validates :name, presence: true
  end

  uses_routine SchoolDistrict::CreateDistrict, as: :create_district,
                                               translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:create_district, name: district_params.name)
  end
end
