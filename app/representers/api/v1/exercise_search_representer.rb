module Api::V1
  class ExerciseSearchRepresenter < OpenStax::Api::V1::AbstractSearchRepresenter
    collection :items,
               inherit: true,
               extend: Api::V1::ExerciseRepresenter
  end
end
