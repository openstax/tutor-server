module Api::V1
  class PerformanceReportsRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: PerformanceReportRepresenter
  end
end
