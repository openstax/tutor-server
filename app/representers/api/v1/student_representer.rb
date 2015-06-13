module Api::V1
  class StudentRepresenter < Roar::Decorator

    include Roar::JSON
    include Representable::Coercion

    property :name,
             type: String,
             readable: true

    property :period_id,
             type: String,
             readable: true

    property :role_id,
             type: String,
             readable: true

  end
end
