module Api::V1
  class PerformanceBookExportsRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: PerformanceBookExportRepresenter
  end
end
