class Api::V1::Research::Sparfa::StudentTaskRepresenter < Api::V1::Research::StudentRepresenter
  nested :pes do
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

  nested :spes do
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
end
