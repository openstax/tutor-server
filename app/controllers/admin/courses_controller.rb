class Admin::CoursesController < ApplicationController
  def index
    @courses = Entity::Course.all
  end

  def create
    Domain::CreateCourse.call
    flash[:notice] = 'The course has been created.'
    redirect_to admin_courses_path
  end
end
