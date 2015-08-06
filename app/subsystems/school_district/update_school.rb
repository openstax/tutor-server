module SchoolDistrict
  class UpdateSchool
    lev_routine express_output: :school

    uses_routine SchoolDistrict::ProcessDistrictChange,
                 as: :process_district_change

    protected
    def exec(id:, attributes: {})
      school = Models::School.find(id)

      if attributes[:school_district_district_id].to_i.zero?
        attributes.delete(:school_district_district_id)
      end

      school.update_attributes(attributes)

      outputs.school = { id: school.id,
                         district_id: school.school_district_district_id,
                         name: school.name }

      run(:process_district_change, school: school)
    end
  end
end
