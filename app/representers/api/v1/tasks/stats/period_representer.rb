module Api::V1
  module Tasks
    module Stats
      # Represents stats for course periods
      class PeriodRepresenter < Roar::Decorator

        include Roar::JSON
        include Representable::Coercion

        property :period_id,
                 type: String,
                 readable: true,
                 writeable: false

        property :name,
                 type: String,
                 readable: true,
                 writeable: false

        property :total_exercises_count,
                 type: Integer,
                 readable: true,
                 writeable: false

        property :complete_exercises_count,
                 type: Integer,
                 readable: true,
                 writeable: false

        property :correct_exercises_count,
                 type: Integer,
                 readable: true,
                 writeable: false

        property :total_tasks_count,
                 type: Integer,
                 readable: true,
                 writeable: false

        property :complete_tasks_count,
                 type: Integer,
                 readable: true,
                 writeable: false

        property :partially_complete_tasks_count,
                 type: Integer,
                 readable: true,
                 writeable: false

        collection :current_pages,
                   readable: true,
                   writable: false,
                   decorator: Api::V1::Tasks::Stats::PageRepresenter

        collection :spaced_pages,
                   readable: true,
                   writable: false,
                   decorator: Api::V1::Tasks::Stats::PageRepresenter

        property :trouble,
                 as: :is_trouble,
                 readable: true,
                 writeable: false,
                 schema_info: { type: 'boolean' }

      end
    end
  end
end
