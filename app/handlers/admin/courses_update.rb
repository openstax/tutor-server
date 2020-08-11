class Admin::CoursesUpdate
  lev_handler

  uses_routine UpdateCourse, as: :update_course, translations: { outputs: { type: :verbatim } }

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    catalog_offering_id = params[:course][:catalog_offering_id]
    offering = Catalog::Models::Offering.find(catalog_offering_id) unless catalog_offering_id.blank?
    params[:course][:is_concept_coach] = offering.is_concept_coach unless offering.nil?
    run(:update_course, params[:id], params[:course])
  end
end
