class Api::V1::CoursesController < Api::V1::ApiController

  resource_description do
    api_versions "v1"
    short_description 'Represents a course in the system'
    description <<-EOS
      Course description to be written...
    EOS
  end

  api :GET, '/courses/:course_id/readings', 'Searches a course\'s readings'
  description <<-EOS 
    #{json_schema(Api::V1::ReadingsSearchRepresenter, include: :readable)}
  EOS
  def search_readings
    course = Course.find(params[:id])
    book = course.book
    OSU::AccessPolicy.require_action_allowed!(:read, current_api_user, current_human_user)
    # outputs = SearchBook.call(q: "user_id:#{current_human_user.id}").outputs
    outputs = CourseContent::SearchReadings.call(course_id: 42, q: "book_id:23 unit_id:42")
    respond_with outputs, represent_with: Api::V1::TaskSearchRepresenter
  end

  def search_exercises

  end

end
