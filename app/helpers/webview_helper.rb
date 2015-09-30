module WebviewHelper

  # Generates data for the FE to read as it boots up
  def bootstrap_data
    {
      user: Api::V1::UserProfileRepresenter.new(current_user),
      courses: Api::V1::CoursesRepresenter.new(
        CollectCourseInfo[user: current_user, with: [:roles, :periods, :ecosystem]]
      )
    }
  end

end
