class Admin::SchoolsCreate
  lev_handler

  paramify :school do
    attribute :name, type: String
    attribute :course_detail_district_id, type: Integer
    validates :name, presence: true
  end

  uses_routine CourseDetail::CreateSchool, as: :create_school

  protected
  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    district = CourseDetail::GetDistrict[id: school_params.course_detail_district_id]
    run(:create_school, name: school_params.name, district_id: district)
  end
end
