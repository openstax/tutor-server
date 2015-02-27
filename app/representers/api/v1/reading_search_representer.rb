module Api::V1
  class ReadingSearchRepresenter < Roar::Decorator

    include Roar::Representer::JSON

    collection :items

  end
end
