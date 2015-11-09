class CoursesController < ApplicationController
  def join
    begin
      course = find_course_by_join_token
      AddUserAsCourseTeacher[course: course, user: current_user]
      redirect_to dashboard_path
    rescue => e
      if e.message == 'user_is_already_teacher_of_course'
        raise UserAlreadyCourseTeacher
      else
        raise InvalidTeacherJoinToken
      end
    end
  end

  private
  def find_course_by_join_token
    profile = GetCourseProfile[attrs: { teacher_join_token: params[:join_token] }]
    Entity::Course.find(profile.course_id)
  end
end

class InvalidTeacherJoinToken < StandardError; end
class UserAlreadyCourseTeacher < StandardError; end
