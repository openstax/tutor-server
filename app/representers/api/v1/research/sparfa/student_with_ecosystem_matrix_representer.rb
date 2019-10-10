class Api::V1::Research::Sparfa::StudentWithEcosystemMatrixRepresenter <
      Api::V1::Research::Sparfa::StudentRepresenter
  property :ecosystem_matrix,
           extend: Api::V1::Research::Sparfa::EcosystemMatrixRepresenter,
           readable: true,
           writeable: false
end
