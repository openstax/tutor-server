class Api::V1::Research::Sparfa::StudentTaskRepresenter < Api::V1::Research::StudentRepresenter
  property :pes,
           extend: Api::V1::Research::Sparfa::Representer,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :spes,
           extend: Api::V1::Research::Sparfa::Representer,
           readable: true,
           writeable: false,
           schema_info: { required: true }

  property :active,
           extend: Api::V1::Research::Sparfa::Representer,
           readable: true,
           writeable: false,
           schema_info: { required: true }
end
