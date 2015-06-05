module Api::V1
  class RosterRepresenter < Roar::Decorator
    include Representable::JSON::Collection

    items extend: StudentRepresenter
  end
end
