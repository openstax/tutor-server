class Api::V1::Demo::Assign::Representer < Api::V1::Demo::BaseRepresenter
  property :course,
           extend: Api::V1::Demo::Assign::Course::Representer,
           class: Demo::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
