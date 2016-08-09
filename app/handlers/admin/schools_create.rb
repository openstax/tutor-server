class Admin::SchoolsCreate
  lev_handler

  paramify :school do
    attribute :name, type: String
    attribute :school_district_district_id, type: Integer
    validates :name, presence: true
  end

  uses_routine SchoolDistrict::CreateSchool, as: :create_school,
                                             translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    district = SchoolDistrict::GetDistrict[id: school_params.school_district_district_id]
    run(:create_school, name: school_params.name, district: district)
  end
end
