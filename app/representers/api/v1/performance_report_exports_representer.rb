module Api::V1
  class PerformanceReportExportsRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: PerformanceReportExportRepresenter
  end
end
