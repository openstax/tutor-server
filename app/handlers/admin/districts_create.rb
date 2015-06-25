class Admin::DistrictsCreate
  lev_handler

  paramify :district do
    attribute :name, type: String
    validates :name, presence: true
  end

  uses_routine CreateDistrict

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(CreateDistrict, name: district_params.name)
  end
end
