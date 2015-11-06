module Api::V1::Courses::Cc

  class PageRepresenter < ::Roar::Decorator

    include ::Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :title,
             type: String,
             readable: true,
             writeable: false

    property :completed,
             type: Integer,
             readable: true,
             writeable: false

    property :completed,
             type: Integer,
             readable: true,
             writeable: false

    property :not_started,
             type: Integer,
             readable: true,
             writeable: false

    property :original_performance,
            type: Float,
            readable: true,
            writeable: false

    property :spaced_practice_performance,
            type: Float,
            readable: true,
            writeable: false

  end

end
