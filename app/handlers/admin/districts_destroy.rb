class Admin::DistrictsDestroy
  lev_handler

  uses_routine SchoolDistrict::DeleteDistrict, as: :delete_district,
                                               translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:delete_district, district: options[:district])
  end
end
