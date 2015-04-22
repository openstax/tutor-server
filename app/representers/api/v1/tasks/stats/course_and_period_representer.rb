module Api::V1
  module Tasks
    module Stats
      # Represents stats for course and periods
      class CourseAndPeriodRepresenter < Roar::Decorator

        include Roar::JSON

        property :id,
                 type: Integer,
                 readable: true,
                 writeable: false

        property :title,
                 type: String,
                 readable: true,
                 writeable: false

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

        collection :current_pages,
                   readable: true,
                   writable: false,
                   decorator: PageRepresenter

        collection :spaced_pages,
                   readable: true,
                   writable: false,
                   decorator: PageRepresenter

      end
    end
  end
end
