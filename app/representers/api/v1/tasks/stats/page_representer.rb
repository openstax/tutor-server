module Api::V1
  module Tasks
    module Stats
      class PageRepresenter < Roar::Decorator

        include Roar::JSON

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

        collection :exercises,
                   type: Object,
                   writeable: false,
                   readable: true,
                   decorator: ExerciseRepresenter

        property :previous_attempt,
                 type: Object,
                 writeable: false,
                 readable: true,
                 decorator: PageRepresenter

      end
    end
  end
end
