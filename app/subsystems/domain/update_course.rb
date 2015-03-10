class Domain::UpdateCourse
  lev_routine

  uses_routine CourseProfile::Api::UpdateProfile, as: :update_profile
  uses_routine Domain::AddUserAsCourseTeacher, as: :assign_teacher

  protected

  def exec(id, course_params)
    course_params.delete(:teacher_ids).reject(&:blank?).each do |user_id|
      user = Entity::User.find(user_id)
      course = Entity::Course.find(id)
      run(:assign_teacher, course: course, user: user)
    end

    run(:update_profile, id, course_params)
  end

end
