class CoursesController < ApplicationController
  def access
    begin
      course = find_course_by_access_token
      AddUserAsCourseTeacher[course: course, user: current_user]
      redirect_to dashboard_path
    rescue
      flash[:error] = "You are trying to join a class as a teacher, but the information you provided is either out of date or does not correspond to an existing course."
      raise InvalidTeacherAccessToken
    end
  end

  private
  def find_course_by_access_token
    profile = GetCourseProfile[attrs: {
      teacher_access_token: params[:access_token]
    }]

    Entity::Course.find(profile.course_id)
  end
end

class InvalidTeacherAccessToken < StandardError; end
