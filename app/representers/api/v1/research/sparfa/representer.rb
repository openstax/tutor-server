class Api::V1::Research::Sparfa::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Coercion

  property :ordered_exercise_numbers,
           type: Array,
           readable: true,
           writeable: false,
           schema_info: {
             description: 'All relevant exercise numbers in the order preferred by SPARFA'
           }

  property :ecosystem_matrix,
           extend: Api::V1::Research::Sparfa::EcosystemMatrixRepresenter,
           readable: true,
           writeable: false
end
