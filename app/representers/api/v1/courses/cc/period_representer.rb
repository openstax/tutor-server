module Api::V1::Courses::Cc

  class PeriodRepresenter < ::Roar::Decorator

    include ::Roar::JSON
    include Representable::Coercion

    property :id,
             type: String,
             readable: true,
             writeable: false

    property :name,
             type: String,
             readable: true,
             writeable: false

    collection :chapters,
               readable: true,
               writeable: false,
               decorator: Api::V1::Courses::Cc::ChapterRepresenter

  end

end
