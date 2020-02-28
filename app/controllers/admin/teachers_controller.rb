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

  def destroy
    teacher = CourseMembership::Models::Teacher.find params[:id]
    CourseMembership::Models::Teacher.transaction do
      teacher.destroy!
      teacher.role.profile.roles.teacher_student.map(&:teacher_student).compact.select do |ts|
        ts.course_profile_course_id == teacher.course_profile_course_id
      end.reject(&:deleted?).each(&:destroy!)
    end
    flash[:notice] = "Teacher \"#{teacher.role.name}\" removed from course."
    redirect_to edit_admin_course_path(teacher.course, anchor: 'teachers')
  end

  def restore
    teacher = CourseMembership::Models::Teacher.find params[:id]
    teacher.restore!
    flash[:notice] = "Teacher \"#{teacher.role.name}\" readded to course."
    redirect_to edit_admin_course_path(teacher.course, anchor: 'teachers')
  end
end
