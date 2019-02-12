module Api::V1

    class NotesRepresenter < Roar::Decorator
        include Representable::JSON::Collection
        items extend: NoteRepresenter
    end

end
