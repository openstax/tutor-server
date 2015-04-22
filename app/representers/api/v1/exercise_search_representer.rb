module Api::V1
  class ExerciseSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter

    collection :items, inherit: true,
                       class: Exercise,
                       decorator: ExerciseRepresenter

  end
end
