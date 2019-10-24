class Api::V1::Research::RootController < Api::V1::Research::BaseController
  api :POST, '/research', <<~EOS
    Retrieve course, period, student and task information
    for the given course_ids or research_identifiers.
  EOS
  description <<~EOS
    Retrieve couse, period, student and task information for courses
    with the given course_ids or students with the given research_identifiers.
  EOS
  def research
    request = Hashie::Mash.new
    consume! request, represent_with: Api::V1::Research::RequestRepresenter
    course_ids = request.course_ids
    research_identifiers = request.research_identifiers
    return render_api_errors('Either course_ids or research_identifiers must be provided') \
      if course_ids.nil? && research_identifiers.nil?

    courses = CourseProfile::Models::Course.preload(:periods)
    courses = courses.where(id: course_ids) unless course_ids.nil?
    courses = courses.joins(students: :role).where(
      students: { role: { research_identifier: research_identifiers } }
    ).distinct unless research_identifiers.nil?

    respond_with courses, represent_with: Api::V1::Research::CoursesRepresenter,
                          location: nil,
                          status: :ok,
                          user_options: { research_identifiers: research_identifiers }
  end
end
