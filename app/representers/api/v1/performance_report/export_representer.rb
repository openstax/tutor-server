module Api::V1::PerformanceReport
  class ExportRepresenter < Roar::Decorator
    include Roar::JSON

    property :filename,
             type: String,
             readable: true

    property :url,
             type: String,
             readable: true

    property :created_at,
             type: String,
             readable: true
  end
end
