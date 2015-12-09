module SchoolDistrict
  class CreateSchool
    lev_routine outputs: { school: :_self },
                uses: { name: SchoolDistrict::ProcessDistrictChange,
                        as: :process_district_change }

    protected
    def exec(name:, district: nil)
      set(school: Models::School.create(name: name,
                                        school_district_district_id: district.try(:id)))

      transfer_errors_from(result.school, {type: :verbatim}, true)

      run(:process_district_change, school: result.school)
    end

  end
end
