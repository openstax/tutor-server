class Api::V1::Research::Sparfa::StudentsRequestRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  collection :research_identifiers,
             type: String,
             readable: false,
             writeable: true
end
