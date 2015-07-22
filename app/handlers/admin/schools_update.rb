class Admin::SchoolsUpdate
  lev_handler

  paramify :school do
    attribute :name, type: String
    validates :name, presence: true
  end

  uses_routine CourseDetail::UpdateSchool, as: :update_school

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    run(:update_school, id: params[:id], attributes: school_params.as_hash(:name))
  end
end
