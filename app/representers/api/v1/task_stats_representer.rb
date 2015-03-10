module Api::V1

  class TaskStatsRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    # Re-used on the previous_attempt and
    # current_pages and spaced_pages properties
    class PageStatFragment < Roar::Decorator
      include Roar::Representer::JSON

      property :page do
        property :id,
          type: Integer,
          readable: true,
          writeable: false

        property :number,
          type: String,
          readable: true,
          writeable: false

        property :title,
          type: String,
          readable: true,
          writeable: false
      end

      property :correct_count,
        type: Integer,
        writeable: false,
        readable: true

      property :incorrect_count,
        type: Integer,
        writeable: false,
        readable: true

      property :previous_attempt,
        type: Object,
        writeable: false,
        readable: true,
        decorator: PageStatFragment
    end

    # Represents course and periods
    class PeriodFragment < Roar::Decorator
      include Roar::Representer::JSON

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
        decorator: PageStatFragment

      collection :spaced_pages,
        readable: true,
        writable: false,
        decorator: PageStatFragment
    end

    property :course,
      type: Object,
      readable: true,
      writeable: false,
      decorator: PeriodFragment

    collection :periods,
      readable: true,
      writable: false,
      decorator: PeriodFragment
  end
end
