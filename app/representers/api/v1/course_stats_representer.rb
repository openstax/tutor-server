module Api::V1
  class CourseStatsRepresenter < Roar::Decorator
    include Roar::JSON

    property :title, readable: true
    property :page_ids, readable: true
    property :children, readable: true
  end
end
