module Api::V1::Courses::Cc

  class ChapterRepresenter < ::Roar::Decorator

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

    collection :pages,
               readable: true,
               writeable: false,
               decorator: Api::V1::Courses::Cc::PageRepresenter

  end

end
