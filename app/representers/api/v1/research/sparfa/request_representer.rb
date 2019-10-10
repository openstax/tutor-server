class Api::V1::Research::Sparfa::RequestRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  collection :course_ids,
             type: String,
             readable: false,
             writeable: true

  collection :research_identifiers,
             type: String,
             readable: true,
             writeable: false
end
