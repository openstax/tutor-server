class CourseProfile::UpdateProfile
  lev_routine

  uses_routine SchoolDistrict::ProcessSchoolChange, as: :process_school_change
  uses_routine Tasks::CourseTimeZoneChanged, as: :time_zone_changed

  protected

  def exec(id, course_params)
    profile = CourseProfile::Models::Profile.find_by(entity_course_id: id)
    profile.update_attributes(course_params)

    run(:process_school_change, course_profile: profile)

    time_zone_change = profile.previous_changes["timezone"]
    if time_zone_change
      run(:time_zone_changed, course: profile.course,
                              old_time_zone_name: time_zone_change.first,
                              new_time_zone_name: time_zone_change.last)
    end
  end

end
