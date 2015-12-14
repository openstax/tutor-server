class SchoolDistrict::ProcessSchoolChange
  lev_routine

  protected

  def exec(course_profile:)

    # TODO eventually SchoolDistrict SS should have its own concept of courses so we don't
    # have to store and interact with a school ID in CourseProfile::Models::Profile

    old_school_id, new_school_id = course_profile.previous_changes['school_district_school_id']

    if old_school_id
      old_school = SchoolDistrict::Models::School.find(old_school_id)
      Legal::MakeChildNotGetParentContracts.call(child: course_profile.course,
                                                 parent: old_school)
    end

    if new_school_id
      new_school = SchoolDistrict::Models::School.find(new_school_id)
      Legal::MakeChildGetParentContracts.call(child: course_profile.course,
                                              parent: new_school)
    end
  end

end
