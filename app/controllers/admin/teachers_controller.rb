class Admin::TeachersController < Admin::BaseController
  def teachers
    course = Entity::Course.find(params[:id])
    (params[:teacher_ids] || []).each do |user_id|
      user = Entity::User.find(user_id)
      AddUserAsCourseTeacher.call(course: course, user: user)
    end

    flash[:notice] = 'Teachers updated.'
    redirect_to edit_admin_course_path(course, anchor: 'teachers')
  end
end
