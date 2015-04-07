module Api::V1
  class CourseStatsRepresenter < Roar::Decorator
    include Roar::JSON

    property :title, readable: true

    property :fields, readable: true
  end
end
