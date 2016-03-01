module Api::V1
  class ExercisesRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: Api::V1::ExerciseRepresenter, class: Hashie::Mash
  end
end
