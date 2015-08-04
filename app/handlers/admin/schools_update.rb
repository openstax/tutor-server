class Admin::SchoolsUpdate
  lev_handler

  paramify :school do
    attribute :name, type: String
    attribute :school_district_district_id, type: Integer
    validates :name, presence: true
  end

  uses_routine SchoolDistrict::UpdateSchool, as: :update_school

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:update_school, id: params[:id],
                        attributes: school_params.as_hash(:name,
                                                          :school_district_district_id))
  end
end
