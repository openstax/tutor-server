class CourseProfile::UpdateProfile
  lev_routine

  uses_routine SchoolDistrict::ProcessSchoolChange, as: :process_school_change

  protected

  def exec(id, course_params)
    profile = CourseProfile::Models::Profile.find_by(entity_course_id: id)
    profile.update_attributes(course_params)

    transfer_errors_from profile, {type: :verbatim}, true

    run(:process_school_change, course_profile: profile)
  end

end
