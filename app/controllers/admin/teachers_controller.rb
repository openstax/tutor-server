class Admin::TeachersController < Admin::BaseController
  def teachers
    course = CourseProfile::Models::Course.find(params[:id])
    (params[:teacher_ids] || []).each do |user_id|
      user = User::User.find(user_id)
      AddUserAsCourseTeacher.call(course: course, user: user)
    end

    flash[:notice] = 'Teachers updated.'
    redirect_to edit_admin_course_path(course, anchor: 'teachers')
  end

  def destroy
    teacher = CourseMembership::Models::Teacher.find(params[:id])
    teacher.destroy
    flash[:notice] = "Teacher \"#{teacher.role.name}\" removed from course."
    redirect_to edit_admin_course_path(teacher.course, anchor: 'teachers')
  end
end
