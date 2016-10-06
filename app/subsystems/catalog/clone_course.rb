module Catalog
  class CloneCourse
    lev_routine express_output: :offering

    protected

    def exec(teacher: , course: )
    offering = Catalog::GetOffering[id: course_params.catalog_offering_id] \
      unless course_params.catalog_offering_id.blank?
    is_concept_coach = offering.nil? ? course_params.is_concept_coach : offering.is_concept_coach
    run(:create_course, name: course_params.name, appearance_code: course_params.appearance_code,
                        school: school, catalog_offering: offering,
                        is_concept_coach: is_concept_coach)

      offering = Models::Offering.create(attributes)
      transfer_errors_from(offering, {type: :verbatim}, true)
      strategy = Strategies::Direct::Offering.new(offering)
      outputs.offering = Offering.new(strategy: strategy)
    end

  end
end
