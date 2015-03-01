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
    #{json_schema(Api::V1::ReadingSearchRepresenter, include: :readable)}
  EOS
  def readings
    books = CourseContent::Api::GetCourseBooks.call(course: Entity::Course.find(params[:id])).outputs.books
    raise NotYetImplemented
  end

end
