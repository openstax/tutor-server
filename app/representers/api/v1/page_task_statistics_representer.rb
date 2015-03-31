module Api::V1

  class PageTaskStatisticsRepresenter < Roar::Decorator

    include Roar::JSON

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

    property :student_count,
      type: Integer,
      writeable: false,
      readable: true

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
      decorator: PageTaskStatisticsRepresenter
  end
end
