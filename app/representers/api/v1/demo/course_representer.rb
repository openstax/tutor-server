class Api::V1::Demo::CourseRepresenter < Api::V1::Demo::BaseRepresenter
  # One of either id or name is required
  property :id,
           type: String,
           readable: false,
           writeable: true

  property :name,
           type: String,
           readable: true,
           writeable: true
end
