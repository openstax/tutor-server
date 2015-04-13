module Api::V1

  # Represents course and periods
  class TaskPlanPeriodStatsRepresenter < Roar::Decorator
    include Roar::JSON

    property :mean_grade_percent,
      type: Integer,
      readable: true,
      writeable: false,
      schema_info: {
        minimum: 0,
        maximum: 100
      }

    property :total_count,
      type: Integer,
      readable: true,
      writeable: false

    property :complete_count,
      type: Integer,
      readable: true,
      writeable: false

    property :partially_complete_count,
      type: Integer,
      readable: true,
      writeable: false

    property :period do
      property :id,
        type: Integer,
        readable: true,
        writeable: false

      property :title,
        type: String,
        readable: true,
        writeable: false
    end

    collection :current_pages,
      readable: true,
      writable: false,
      decorator: PageTaskStatisticsRepresenter

    collection :spaced_pages,
      readable: true,
      writable: false,
      decorator: PageTaskStatisticsRepresenter
  end

end
