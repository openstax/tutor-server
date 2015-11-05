class CoursesController < ApplicationController
  def join
    begin
      course = find_course_by_join_token
      AddUserAsCourseTeacher[course: course, user: current_user]
      redirect_to dashboard_path
    rescue
      flash[:error] = "You are trying to join a class as a teacher, but the information you provided is either out of date or does not correspond to an existing course."
      raise InvalidTeacherJoinToken
    end
  end

  private
  def find_course_by_join_token
    profile = GetCourseProfile[attrs: { teacher_join_token: params[:join_token] }]
    Entity::Course.find(profile.course_id)
  end
end

class InvalidTeacherJoinToken < StandardError; end
