class Admin::CoursesUpdate
  lev_handler

  uses_routine UpdateCourse, as: :update_course

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    catalog_offering_id = params[:course][:catalog_offering_id]
    offering = Catalog::GetOffering[id: catalog_offering_id] unless catalog_offering_id.blank?
    run(:update_course, params[:id], params[:course])
  end
end
