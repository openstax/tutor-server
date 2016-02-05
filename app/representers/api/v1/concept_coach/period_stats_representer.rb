module Api::V1
  module ConceptCoach
    # Represents stats for course periods
    class PeriodStatsRepresenter < Roar::Decorator

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

      property :mean_grade_percent,
               type: Hash,
               readable: true,
               writeable: false do
        property :based_on_attempted_problems,
                 type: Integer,
                 readable: true,
                 writeable: false,
                 schema_info: {
                   minimum: 0,
                   maximum: 100
                 }

        property :based_on_assigned_problems,
                 type: Integer,
                 readable: true,
                 writeable: false,
                 schema_info: {
                   minimum: 0,
                   maximum: 100
                 }
      end

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
                 writeable: false,
                 decorator: Api::V1::Tasks::Stats::PageRepresenter

      collection :spaced_pages,
                 readable: true,
                 writeable: false,
                 decorator: Api::V1::Tasks::Stats::PageRepresenter

      property :trouble,
               as: :is_trouble,
               readable: true,
               writeable: false,
               schema_info: { type: 'boolean' }

    end
  end
end
