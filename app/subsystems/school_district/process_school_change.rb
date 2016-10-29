class SchoolDistrict::ProcessSchoolChange
  lev_routine

  protected

  def exec(course:)

    old_school_id, new_school_id = course.previous_changes['school_district_school_id']

    if old_school_id
      old_school = SchoolDistrict::Models::School.find(old_school_id)
      Legal::MakeChildNotGetParentContracts[child: course, parent: old_school]
    end

    if new_school_id
      new_school = SchoolDistrict::Models::School.find(new_school_id)
      Legal::MakeChildGetParentContracts[child: course, parent: new_school]
    end
  end

end
