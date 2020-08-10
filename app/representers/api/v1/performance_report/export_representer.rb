module Api::V1::PerformanceReport
  class ExportRepresenter < Roar::Decorator
    include Roar::JSON

    property :filename,
             type: String,
             readable: true,
             writeable: false

    property :url,
             type: String,
             readable: true,
             writeable: false

    property :created_at,
             type: String,
             readable: true,
             writeable: false,
             getter: ->(*) { DateTimeUtilities.to_api_s created_at }
  end
end
