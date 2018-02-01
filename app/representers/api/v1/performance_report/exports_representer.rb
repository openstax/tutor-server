module Api::V1::PerformanceReport
  class ExportsRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: ExportRepresenter
  end
end
