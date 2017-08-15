class Admin::TeachersController < Admin::BaseController
  def teachers
    course = CourseProfile::Models::Course.find(params[:id])
    results = (params[:teacher_ids] || []).map do |user_id|
      user = User::User.find(user_id)
      AddUserAsCourseTeacher.call(course: course, user: user)
    end

    errors = results.flat_map(&:errors)
    if errors.empty?
      flash[:notice] = 'Teachers updated.'
    else
      flash[:error] = errors.first.code.to_s.humanize
    end
    redirect_to edit_admin_course_path(course, anchor: 'teachers')
  end

  def delete
    teacher = CourseMembership::Models::Teacher.find(params[:id])
    teacher.destroy
    flash[:notice] = "Teacher \"#{teacher.role.name}\" removed from course."
    redirect_to edit_admin_course_path(teacher.course, anchor: 'teachers')
  end

  def undelete
    teacher = CourseMembership::Models::Teacher.find(params[:id])
    teacher.restore
    flash[:notice] = "Teacher \"#{teacher.role.name}\" readded to course."
    redirect_to edit_admin_course_path(teacher.course, anchor: 'teachers')
  end
end
