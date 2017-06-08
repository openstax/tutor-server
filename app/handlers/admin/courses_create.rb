class Admin::CoursesCreate
  lev_handler

  paramify :course do
    attribute :name, type: String
    attribute :term, type: String
    attribute :year, type: Integer
    attribute :num_sections, type: Integer
    attribute :starts_at, type: DateTime
    attribute :ends_at, type: DateTime
    attribute :appearance_code, type: String
    attribute :school_district_school_id, type: Integer
    attribute :catalog_offering_id, type: Integer
    attribute :is_test, type: ActiveAttr::Typecasting::Boolean
    attribute :is_preview, type: ActiveAttr::Typecasting::Boolean
    attribute :is_concept_coach, type: ActiveAttr::Typecasting::Boolean
    attribute :is_college, type: ActiveAttr::Typecasting::Boolean
    validates :name, :term, :year, :num_sections, presence: true
    validates :is_test, :is_preview, :is_concept_coach, :is_college, inclusion: [true, false]
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

    run(:create_course, name: course_params.name,
                        term: course_params.term,
                        year: course_params.year,
                        num_sections: course_params.num_sections,
                        starts_at: course_params.starts_at,
                        ends_at: course_params.ends_at,
                        is_test: course_params.is_test,
                        is_preview: course_params.is_preview,
                        is_concept_coach: course_params.is_concept_coach,
                        is_college: course_params.is_college,
                        catalog_offering: offering,
                        appearance_code: course_params.appearance_code,
                        school: school)
  end
end
