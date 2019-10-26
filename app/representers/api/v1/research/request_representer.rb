class Api::V1::Research::RequestRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  collection :course_ids,
             type: String,
             readable: false,
             writeable: true

  collection :research_identifiers,
             type: String,
             readable: false,
             writeable: true
end
