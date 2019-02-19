module Api::V1

    class HighlightsRepresenter < Roar::Decorator
        include Representable::JSON::Collection
        items extend: HighlightRepresenter
    end

end
