class CoursesController < ApplicationController
  def access
    course = Entity::Course.find(params[:id])

    if course.teacher_access_token == params[:access_token]
      AddUserAsCourseTeacher[course: course, user: current_user]
      redirect_to dashboard_path
    else
      flash[:error] = "You are trying to join a class as a teacher, but the information you provided is either out of date or does not correspond to an existing course."
      raise InvalidTeacherAccessToken
    end
  end
end

class InvalidTeacherAccessToken < StandardError; end
