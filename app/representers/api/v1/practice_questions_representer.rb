module Api::V1
  class PracticeQuestionsRepresenter < Roar::Decorator
    include Representable::JSON::Collection
    items extend: PracticeQuestionRepresenter
  end
end
