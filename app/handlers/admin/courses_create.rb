class Admin::CoursesCreate
  lev_handler

  paramify :course do
    attribute :name, type: String
    attribute :appearance_code, type: String
    attribute :school_district_school_id, type: Integer
    attribute :catalog_offering_id, type: Integer
    attribute :is_concept_coach, type: ActiveAttr::Typecasting::Boolean
    validates :name, presence: true
  end

  uses_routine CreateCourse

  protected

  def authorized?
    true # already authenticated in admin controller base
  end

  def handle
    school = SchoolDistrict::GetSchool[id: course_params.school_district_school_id] \
      unless course_params.school_district_school_id.blank?
    offering = Catalog::GetOffering[id: course_params.catalog_offering_id] \
      unless course_params.catalog_offering_id.blank?
    is_concept_coach = offering.nil? ? course_params.is_concept_coach : offering.is_concept_coach
    run(:create_course, name: course_params.name, appearance_code: course_params.appearance_code,
                        school: school, catalog_offering: offering,
                        is_concept_coach: is_concept_coach)
  end
end
