class SchoolDistrict::ProcessDistrictChange
  lev_routine

  protected

  def exec(school:)

    old_district_id, new_district_id = school.previous_changes['school_district_district_id']

    if old_district_id
      old_district = SchoolDistrict::Models::District.find(old_district_id)
      Legal::MakeChildNotGetParentContracts[child: school, parent: old_district]
    end

    if new_district_id
      new_district = SchoolDistrict::Models::District.find(new_district_id)
      Legal::MakeChildGetParentContracts[child: school, parent: new_district]
    end

  end
end
